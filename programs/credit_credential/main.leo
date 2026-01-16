program credit_credential;

import std::address;
import std::hash;
import std::date;

// A record representing a private credit credential for a user. The actual credit
// score is never exposed on‑chain; only a hash of the score and a boolean flag
// indicating whether the score meets a specified threshold are stored. A
// nullifier prevents reuse of the same proof.
record CreditCredential {
    owner: address,
    issuer: address,
    score_hash: field,
    threshold_met: bool,
    expiration: u64,
    nullifier: field,
}

// Issues a new credit credential. In a production system, the issuer would
// compute the score hash and threshold flag off‑chain based on the user’s
// credit information. For this example we simply accept them as inputs and
// record the issuer as the constant caller of the transition.
transition issue_credit(
    owner: address,
    score_hash: field,
    threshold_met: bool,
    expiration: u64,
    nullifier: field,
) -> CreditCredential {
    let issuer_addr: address = address::const_caller();
    let credential: CreditCredential = CreditCredential {
        owner: owner,
        issuer: issuer_addr,
        score_hash: score_hash,
        threshold_met: threshold_met,
        expiration: expiration,
        nullifier: nullifier,
    };
    credential
}

// Verifies off‑chain that a credential is still valid. The verifier checks that
// the threshold flag is true and that the credential has not expired. The
// calling application must supply the current timestamp.
function verify_offchain(
    credential: CreditCredential,
    current_time: u64
) -> bool {
    if !credential.threshold_met {
        return false;
    }
    if current_time >= credential.expiration {
        return false;
    }
    true
}

// Generates a proof for a credit credential. The proof is simply a hash of
// deterministic data derived from the credential so that the verifier can
// recompute and compare on‑chain. We return both the proof hash and the
// nullifier; the nullifier must accompany the proof so that the gateway can
// prevent reuse.
function prove_credit(
    credential: CreditCredential
) -> (field, field) {
    // Combine the owner field representation and score hash into a single
    // message. Because the score hash is itself a hash of the real score,
    // nothing sensitive is revealed here.
    let data: field = credential.owner.to_field() + credential.score_hash;
    let proof_hash: field = hash::hash_to_field(data);
    (proof_hash, credential.nullifier)
}

// Verifies a credit proof on‑chain. The verifier recomputes the expected hash
// and ensures that the provided nullifier matches the credential’s nullifier.
// It also checks that the threshold flag is true. Because the credential
// structure is passed into this function as a private record, no user data is
// revealed.
function verify_onchain(
    proof_hash: field,
    nullifier: field,
    credential: CreditCredential
) -> bool {
    // Ensure the nullifier matches the credential to prevent substitution
    if credential.nullifier != nullifier {
        return false;
    }
    // Recompute the expected hash
    let data: field = credential.owner.to_field() + credential.score_hash;
    let expected: field = hash::hash_to_field(data);
    if expected != proof_hash {
        return false;
    }
    // Check that the user actually met the threshold
    if !credential.threshold_met {
        return false;
    }
    true
}
