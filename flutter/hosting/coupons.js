import { initializeApp } from "https://www.gstatic.com/firebasejs/12.16.0/firebase-app.js";
import {
  getAuth,
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithPopup,
  signOut,
} from "https://www.gstatic.com/firebasejs/12.16.0/firebase-auth.js";
import {
  collection,
  doc,
  getDoc,
  getDocs,
  getFirestore,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from "https://www.gstatic.com/firebasejs/12.16.0/firebase-firestore.js";

const firebaseConfig = {
  projectId: "balokkosong-54afe",
  appId: "1:456475995990:web:9b9fc069f4c819dc17b0f7",
  storageBucket: "balokkosong-54afe.firebasestorage.app",
  apiKey: "AIzaSyDKoq7dAGmE4ToatRZKMjZrDw86vmIR-8Y",
  authDomain: "balokkosong-54afe.firebaseapp.com",
  messagingSenderId: "456475995990",
};

const developerEmail = "ah.subhan@gmail.com";
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const loginPanel = document.querySelector("#login-panel");
const adminPanel = document.querySelector("#admin-panel");
const loginButton = document.querySelector("#login-button");
const logoutButton = document.querySelector("#logout-button");
const form = document.querySelector("#coupon-form");
const formMessage = document.querySelector("#form-message");
const couponList = document.querySelector("#coupon-list");
const feedbackList = document.querySelector("#feedback-list");
const saveButton = document.querySelector("#save-button");

function localDateTimeValue(date) {
  const offset = date.getTimezoneOffset() * 60000;
  return new Date(date.getTime() - offset).toISOString().slice(0, 16);
}

const initialStart = new Date();
const initialEnd = new Date();
initialEnd.setDate(initialEnd.getDate() + 30);
document.querySelector("#starts-at").value = localDateTimeValue(initialStart);
document.querySelector("#expires-at").value = localDateTimeValue(initialEnd);

loginButton.addEventListener("click", async () => {
  loginButton.disabled = true;
  try {
    await signInWithPopup(auth, new GoogleAuthProvider());
  } catch (error) {
    alert(`Login belum berhasil: ${error.message}`);
  } finally {
    loginButton.disabled = false;
  }
});

logoutButton.addEventListener("click", () => signOut(auth));
document.querySelector("#refresh-button").addEventListener("click", loadCoupons);
document
  .querySelector("#feedback-refresh-button")
  .addEventListener("click", loadFeedback);

onAuthStateChanged(auth, async (user) => {
  const allowed = user?.email?.toLowerCase() === developerEmail;
  loginPanel.hidden = allowed;
  adminPanel.hidden = !allowed;
  if (user && !allowed) {
    await signOut(auth);
    alert("Akun ini tidak memiliki akses administrator.");
    return;
  }
  if (allowed) {
    document.querySelector("#admin-email").textContent = user.email;
    await Promise.all([loadCoupons(), loadFeedback()]);
  }
});

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  const code = document
    .querySelector("#code")
    .value.trim()
    .toUpperCase()
    .replace(/\s+/g, "");
  const rewards = {
    tokens: Number(document.querySelector("#reward-tokens").value || 0),
    energy: Number(document.querySelector("#reward-energy").value || 0),
    themePack: document.querySelector("#reward-theme").checked,
    customTheme: document.querySelector("#reward-custom").checked,
    noAds: document.querySelector("#reward-no-ads").checked,
  };
  if (!/^[A-Z0-9-]{4,24}$/.test(code)) {
    showFormMessage("Kode harus 4–24 karakter: huruf, angka, atau tanda -.", true);
    return;
  }
  if (
    rewards.tokens <= 0 &&
    rewards.energy <= 0 &&
    !rewards.themePack &&
    !rewards.customTheme &&
    !rewards.noAds
  ) {
    showFormMessage("Pilih minimal satu hadiah.", true);
    return;
  }

  saveButton.disabled = true;
  showFormMessage("Menyimpan…");
  try {
    const couponRef = doc(db, "coupons", code);
    const existing = await getDoc(couponRef);
    const existingData = existing.data();
    await setDoc(couponRef, {
      code,
      label: document.querySelector("#label").value.trim(),
      active: document.querySelector("#active").checked,
      startsAt: Timestamp.fromDate(
        new Date(document.querySelector("#starts-at").value),
      ),
      expiresAt: Timestamp.fromDate(
        new Date(document.querySelector("#expires-at").value),
      ),
      maxRedemptions: Number(
        document.querySelector("#max-redemptions").value,
      ),
      redemptionCount: existingData?.redemptionCount ?? 0,
      rewards,
      createdAt: existingData?.createdAt ?? serverTimestamp(),
      createdBy: auth.currentUser.uid,
      updatedAt: serverTimestamp(),
      ...(existingData?.lastRedeemedAt
        ? { lastRedeemedAt: existingData.lastRedeemedAt }
        : {}),
    });
    showFormMessage(`Kupon ${code} berhasil disimpan.`);
    form.reset();
    document.querySelector("#reward-tokens").value = "10";
    document.querySelector("#reward-energy").value = "0";
    document.querySelector("#max-redemptions").value = "100";
    document.querySelector("#active").checked = true;
    document.querySelector("#starts-at").value =
      localDateTimeValue(new Date());
    const end = new Date();
    end.setDate(end.getDate() + 30);
    document.querySelector("#expires-at").value = localDateTimeValue(end);
    await loadCoupons();
  } catch (error) {
    showFormMessage(`Kupon belum tersimpan: ${error.message}`, true);
  } finally {
    saveButton.disabled = false;
  }
});

function showFormMessage(message, error = false) {
  formMessage.textContent = message;
  formMessage.style.color = error ? "#ff9db5" : "#9de2b7";
}

async function loadCoupons() {
  couponList.innerHTML = '<p class="empty-state">Memuat kupon…</p>';
  try {
    const snapshot = await getDocs(
      query(collection(db, "coupons"), orderBy("createdAt", "desc")),
    );
    const coupons = snapshot.docs.map((item) => ({
      id: item.id,
      ...item.data(),
    }));
    renderCoupons(coupons);
  } catch (error) {
    couponList.innerHTML =
      `<p class="empty-state">Data belum dapat dimuat: ${escapeHtml(error.message)}</p>`;
  }
}

function renderCoupons(coupons) {
  document.querySelector("#coupon-count").textContent = coupons.length;
  document.querySelector("#active-count").textContent =
    coupons.filter((coupon) => coupon.active).length;
  document.querySelector("#claim-count").textContent = coupons.reduce(
    (total, coupon) => total + (coupon.redemptionCount || 0),
    0,
  );
  if (!coupons.length) {
    couponList.innerHTML = '<p class="empty-state">Belum ada kupon.</p>';
    return;
  }
  couponList.innerHTML = "";
  coupons.forEach((coupon) => {
    const card = document.createElement("article");
    card.className = "coupon-card";
    card.innerHTML = `
      <div class="coupon-card-top">
        <span class="coupon-code">${escapeHtml(coupon.code)}</span>
        <span class="status-pill ${coupon.active ? "" : "off"}">
          ${coupon.active ? "AKTIF" : "NONAKTIF"}
        </span>
      </div>
      <p class="coupon-label">${escapeHtml(coupon.label)}</p>
      <p class="coupon-reward">${escapeHtml(rewardLabel(coupon.rewards))}</p>
      <p class="coupon-meta">
        ${coupon.redemptionCount || 0}/${coupon.maxRedemptions} dipakai ·
        berakhir ${formatDate(coupon.expiresAt)}
      </p>
      <div class="coupon-card-actions">
        <button class="ghost-button toggle-button">
          ${coupon.active ? "Nonaktifkan" : "Aktifkan"}
        </button>
      </div>
    `;
    card.querySelector(".toggle-button").addEventListener("click", async () => {
      try {
        await updateDoc(doc(db, "coupons", coupon.id), {
          active: !coupon.active,
          updatedAt: serverTimestamp(),
        });
        await loadCoupons();
      } catch (error) {
        alert(`Status belum berubah: ${error.message}`);
      }
    });
    couponList.append(card);
  });
}

function rewardLabel(rewards = {}) {
  const items = [];
  if (rewards.tokens) items.push(`+${rewards.tokens} token`);
  if (rewards.energy) items.push(`+${rewards.energy} energy`);
  if (rewards.themePack) items.push("Tema Neon & Ocean");
  if (rewards.customTheme) items.push("Tema Custom");
  if (rewards.noAds) items.push("Bebas iklan");
  return items.join(" · ") || "Hadiah belum dipilih";
}

function formatDate(timestamp) {
  if (!timestamp?.toDate) return "-";
  return new Intl.DateTimeFormat("id-ID", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(timestamp.toDate());
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

async function loadFeedback() {
  feedbackList.innerHTML = '<p class="empty-state">Memuat feedback…</p>';
  try {
    const snapshot = await getDocs(
      query(collection(db, "feedback"), orderBy("createdAt", "desc")),
    );
    const feedback = snapshot.docs.map((item) => ({
      id: item.id,
      ...item.data(),
    }));
    renderFeedback(feedback);
  } catch (error) {
    feedbackList.innerHTML =
      `<p class="empty-state">Feedback belum dapat dimuat: ${escapeHtml(error.message)}</p>`;
  }
}

function renderFeedback(feedback) {
  if (!feedback.length) {
    feedbackList.innerHTML = '<p class="empty-state">Belum ada feedback.</p>';
    return;
  }
  feedbackList.innerHTML = "";
  feedback.forEach((item) => {
    const name = item.senderName || item.displayName || "Tanpa nama";
    const status = feedbackStatus(item.status);
    const attachment = item.attachment || null;
    const attachmentMarkup = attachment?.url
      ? `<a class="feedback-attachment" href="${escapeHtml(attachment.url)}" target="_blank" rel="noopener noreferrer">
          📎 ${escapeHtml(attachment.name || "Buka lampiran")}
        </a>`
      : "";
    const card = document.createElement("article");
    card.className = "feedback-card";
    card.innerHTML = `
      <div class="feedback-card-top">
        <span class="feedback-name">${escapeHtml(name)}</span>
        <span class="status-pill ${item.status === "resolved" ? "" : "off"}">
          ${escapeHtml(status)}
        </span>
      </div>
      <div class="feedback-email">${escapeHtml(item.email || "Email tidak tersedia")}</div>
      <p class="feedback-message">${escapeHtml(item.message || "Tidak ada isi pesan")}</p>
      ${attachmentMarkup}
      <div class="feedback-meta">
        ${escapeHtml(item.platform || "perangkat tidak diketahui")} ·
        v${escapeHtml(item.appVersion || "-")} (${escapeHtml(item.buildNumber || "-")})
      </div>
      <div class="feedback-date">${formatDate(item.createdAt)}</div>
      ${item.status !== "resolved" ? `
        <div class="feedback-actions">
          ${item.status === "new" || item.status === "pending_review"
            ? '<button class="ghost-button read-button">Sudah dibaca</button>'
            : ""}
          <button class="ghost-button resolve-button">Selesai</button>
        </div>
      ` : ""}
    `;

    const readButton = card.querySelector(".read-button");
    if (readButton) {
      readButton.addEventListener("click", () =>
        updateFeedbackStatus(item.id, "read"),
      );
    }
    const resolveButton = card.querySelector(".resolve-button");
    if (resolveButton) {
      resolveButton.addEventListener("click", () =>
        updateFeedbackStatus(item.id, "resolved"),
      );
    }
    feedbackList.append(card);
  });
}

async function updateFeedbackStatus(id, status) {
  try {
    await updateDoc(doc(db, "feedback", id), {
      status,
      reviewedAt: serverTimestamp(),
      reviewedBy: auth.currentUser.uid,
    });
    await loadFeedback();
  } catch (error) {
    alert(`Status feedback belum tersimpan: ${error.message}`);
  }
}

function feedbackStatus(status) {
  if (status === "resolved") return "SELESAI";
  if (status === "read") return "SUDAH DIBACA";
  if (status === "pending_review") return "PERLU DITINJAU";
  return "BARU";
}
