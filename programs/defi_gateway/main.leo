program defi_gateway;

// Import the identity and credit credential programs so we can call their
// verification functions. These programs must reside in the same package
// hierarchy (programs/identity_credential and programs/credit_credential).
import identity_credential;
import credit_credential;

// Maintain two mappings of used nullifiers for identity and credit proofs.
// These mappings prevent a user from reusing a proof to bypass access
// controls multiple times.
mapping id_nullifiers: field -> bool;
mapping credit_nullifiers: field -> bool;

// Verifies that a user holds a valid identity and credit credential. The
// caller supplies the proof hashes and nullifiers along with the underlying
// credential records. This function checks that neither nullifier has been
// used before, that the proofs are valid according to the imported
// verification functions, and then records the nullifiers as used.
transition verify_access(
    id_proof: field,
    id_nullifier: field,
    credit_proof: field,
    credit_nullifier: field,
    identity: identity_credential::IdentityCredential,
    credit: credit_credential::CreditCredential
) -> bool {
    // Reject if the nullifiers have already been consumed
    if id_nullifiers.contains(id_nullifier) {
        return false;
    }
    if credit_nullifiers.contains(credit_nullifier) {
        return false;
    }
    // Call into the imported programs to verify each proof
    if !identity_credential::verify_onchain(id_proof, id_nullifier, identity) {
        return false;
    }
    if !credit_credential::verify_onchain(credit_proof, credit_nullifier, credit) {
        return false;
    }
    // Record the nullifiers to prevent re‑use
    id_nullifiers[id_nullifier] = true;
    credit_nullifiers[credit_nullifier] = true;
    true
}

// A simple deposit transition that requires the caller to present valid proofs.
// The amount parameter is included for completeness; in a real implementation
// this function would update encrypted balances on‑chain. Here it simply
// returns true if access verification succeeds.
transition deposit(
    id_proof: field,
    id_nullifier: field,
    credit_proof: field,
    credit_nullifier: field,
    identity: identity_credential::IdentityCredential,
    credit: credit_credential::CreditCredential,
    amount: u64
) -> bool {
    let permitted: bool = verify_access(id_proof, id_nullifier, credit_proof, credit_nullifier, identity, credit);
    if !permitted {
        return false;
    }
    // Insert deposit logic here (e.g., update user balance). For now just
    // return true to indicate the deposit would succeed.
    true
}
