program identity_credential;

import std::address;
import std::hash;
import std::date;

record IdentityCredential {
    owner: address,
    issuer: address,
    dob_hash: field,
    nationality_hash: field,
    kyc_status: bool,
    expiration: u64,
    nullifier: field,
}

transition issue_identity(
    owner: address,
    dob_hash: field,
    nationality_hash: field,
    kyc_status: bool,
    expiration: u64
) -> IdentityCredential {
    let issuer_addr: address = address::const_caller();
    let nullifier: field = hash::hash_to_field(owner.to_field() + dob_hash);
    let credential = IdentityCredential {
        owner,
        issuer: issuer_addr,
        dob_hash,
        nationality_hash,
        kyc_status,
        expiration,
        nullifier,
    };
    credential
}

function verify_offchain(credential: IdentityCredential, current_time: u64) -> bool {
    if !credential.kyc_status {
        return false;
    }
    if current_time >= credential.expiration {
        return false;
    }
    true
}

function prove_identity(credential: IdentityCredential) -> (field, field) {
    let data: field = credential.owner.to_field() + credential.dob_hash + credential.nationality_hash;
    let proof_hash: field = hash::hash_to_field(data);
    (proof_hash, credential.nullifier)
}

function verify_onchain(proof_hash: field, nullifier: field, credential: IdentityCredential) -> bool {
    if credential.nullifier != nullifier {
        return false;
    }
    let data: field = credential.owner.to_field() + credential.dob_hash + credential.nationality_hash;
    let expected: field = hash::hash_to_field(data);
    if expected != proof_hash {
        return false;
    }
    if !credential.kyc_status {
        return false;
    }
    // Ensure credential not expired relative to current on-chain timestamp
    if date::unix_timestamp() >= credential.expiration {
        return false;
    }
    true
}
