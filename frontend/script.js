const identityCredentials = {};
const creditCredentials = {};
const proofs = {};

function log(msg) {
  const logEl = document.getElementById('log');
  logEl.textContent += msg + '\n';
}

async function sha256(str) {
  const buffer = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(str));
  return Array.from(new Uint8Array(buffer)).map(b => b.toString(16).padStart(2, '0')).join('');
}

document.getElementById('issue_identity_btn').addEventListener('click', async () => {
  const owner = document.getElementById('id_owner').value;
  const issuer = document.getElementById('id_issuer').value;
  const dob = document.getElementById('id_dob').value;
  const nationality = document.getElementById('id_nationality').value;
  const kyc = document.getElementById('id_kyc').checked;
  const expiration = document.getElementById('id_expiration').value;
  if (!owner || !issuer || !dob || !nationality || !expiration) {
    log('Please fill all identity fields.');
    return;
  }
  const dobHash = await sha256(dob);
  const nationalityHash = await sha256(nationality.toLowerCase());
  identityCredentials[owner] = {
    owner,
    issuer,
    dobHash,
    nationalityHash,
    kyc,
    expiration: new Date(expiration).getTime()
  };
  log('Issued identity credential for ' + owner);
});

document.getElementById('issue_credit_btn').addEventListener('click', () => {
  const owner = document.getElementById('cred_owner').value;
  const issuer = document.getElementById('cred_issuer').value;
  const score = parseInt(document.getElementById('cred_score').value, 10);
  const threshold = parseInt(document.getElementById('cred_threshold').value, 10);
  const expiration = document.getElementById('cred_expiration').value;
  if (!owner || !issuer || isNaN(score) || isNaN(threshold) || !expiration) {
    log('Please fill all credit fields.');
    return;
  }
  creditCredentials[owner] = {
    owner,
    issuer,
    score,
    threshold,
    thresholdMet: score >= threshold,
    expiration: new Date(expiration).getTime()
  };
  log('Issued credit credential for ' + owner);
});

document.getElementById('generate_proof_btn').addEventListener('click', () => {
  const owner = document.getElementById('proof_owner').value;
  if (!owner) {
    log('Enter user address.');
    return;
  }
  const idCred = identityCredentials[owner];
  const credCred = creditCredentials[owner];
  const now = Date.now();
  if (!idCred) {
    log('No identity credential for ' + owner);
    return;
  }
  if (!credCred) {
    log('No credit credential for ' + owner);
    return;
  }
  if (!idCred.kyc) {
    log('KYC not verified for ' + owner);
    return;
  }
  if (!credCred.thresholdMet) {
    log('Credit threshold not met for ' + owner);
    return;
  }
  if (idCred.expiration < now) {
    log('Identity credential expired for ' + owner);
    return;
  }
  if (credCred.expiration < now) {
    log('Credit credential expired for ' + owner);
    return;
  }
  const proof = Math.random().toString(36).substring(2) + Date.now();
  proofs[owner] = { proof, used: false };
  log('Generated proof for ' + owner + ': ' + proof);
});

document.getElementById('deposit_btn').addEventListener('click', () => {
  const owner = document.getElementById('proof_owner').value;
  const amount = parseFloat(document.getElementById('deposit_amount').value);
  if (!owner || isNaN(amount) || amount <= 0) {
    log('Enter user address and positive deposit amount.');
    return;
  }
  const proofObj = proofs[owner];
  if (!proofObj) {
    log('No proof for ' + owner + '. Generate proof first.');
    return;
  }
  if (proofObj.used) {
    log('Proof already used for ' + owner);
    return;
  }
  proofObj.used = true;
  log('Deposit of ' + amount + ' accepted for ' + owner);
});
