# ZK-Compliant DeFi Gateway

This project implements a privacy-preserving DeFi access layer on Aleo. It verifies users' KYC/AML and creditworthiness via zero-knowledge proofs (e.g., using zPass) without exposing their personal data. Users generate proofs locally and the gateway verifies them on-chain before allowing interaction with DeFi protocols.

## Components

- **Identity credential program (Leo)**: Stores and verifies KYC credentials (e.g., age, nationality, KYC status) as encrypted records on Aleo.
- **Credit credential program (Leo)**: Stores an encrypted representation of a user's credit score and verifies that it meets a threshold.
- **DeFi gateway contract (Leo)**: Accepts zero-knowledge proofs from users, checks compliance rules, and then forwards authorized transactions to underlying DeFi protocols.
- **Frontend and proof generator (WASM)**: Provides a simple interface for users to request credentials, generate proofs locally, and interact with the gateway.

This repository will include the necessary Leo programs and example frontend to demonstrate the concept.
