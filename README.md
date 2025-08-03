# Blockchain-Based Sustainable Fisheries Management and Seafood Traceability System

## Overview

This system provides a comprehensive blockchain solution for sustainable fisheries management and seafood traceability using Clarity smart contracts on the Stacks blockchain. The system ensures transparency, accountability, and sustainability in the fishing industry through five interconnected smart contracts.

## System Components

### 1. Fishing Vessel Tracking Contract (`vessel-tracking.clar`)
- Monitors vessel locations and fishing activity
- Prevents illegal fishing through real-time tracking
- Records vessel registration and movement history
- Implements geofencing for restricted areas

### 2. Catch Quota Enforcement Contract (`quota-enforcement.clar`)
- Manages sustainable catch limits for different species
- Tracks individual fisherman quotas
- Enforces seasonal restrictions
- Prevents overfishing through automated quota management

### 3. Seafood Origin Verification Contract (`origin-verification.clar`)
- Tracks seafood from harvest to consumer
- Prevents mislabeling and fraud
- Maintains chain of custody records
- Enables consumer verification of seafood authenticity

### 4. Bycatch Reduction Monitoring Contract (`bycatch-monitoring.clar`)
- Measures unintended capture of non-target species
- Implements bycatch reduction incentives
- Tracks fishing method effectiveness
- Promotes sustainable fishing practices

### 5. Marine Protected Area Compliance Contract (`mpa-compliance.clar`)
- Enforces fishing restrictions in sensitive marine ecosystems
- Manages protected area boundaries
- Monitors compliance violations
- Implements penalty systems for violations

## Key Features

- **Transparency**: All fishing activities are recorded on the blockchain
- **Traceability**: Complete seafood supply chain tracking
- **Sustainability**: Automated quota and protected area enforcement
- **Fraud Prevention**: Immutable records prevent seafood mislabeling
- **Compliance Monitoring**: Real-time violation detection and reporting

## Data Structures

### Vessel Registration
- Vessel ID, owner, license information
- GPS tracking capabilities
- Fishing permits and restrictions

### Catch Records
- Species, quantity, location, timestamp
- Fishing method and gear used
- Quota allocation and remaining limits

### Supply Chain Tracking
- Harvest details, processing steps
- Transportation and storage conditions
- Retail and consumer endpoints

### Protected Area Management
- Boundary coordinates and restrictions
- Seasonal closures and special regulations
- Violation tracking and penalties

## Installation

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Deploy contracts using `clarinet deploy`

## Testing

Run the test suite with:
\`\`\`bash
npm test
\`\`\`

## Usage

### For Fishing Vessels
1. Register vessel with tracking contract
2. Report catch data to quota enforcement
3. Maintain GPS tracking during fishing operations
4. Comply with protected area restrictions

### For Processors/Retailers
1. Verify seafood origin using verification contract
2. Update supply chain records during processing
3. Maintain traceability throughout distribution

### For Regulators
1. Monitor vessel activities and quota compliance
2. Enforce protected area restrictions
3. Track bycatch reduction progress
4. Generate compliance reports

## Contract Interactions

Each contract operates independently but shares common data structures for interoperability. The system maintains referential integrity through consistent vessel IDs, catch IDs, and location coordinates across all contracts.

## Security Considerations

- All sensitive operations require proper authorization
- Immutable records prevent data tampering
- Multi-signature requirements for critical functions
- Regular audit trails for compliance verification

## Future Enhancements

- Integration with IoT sensors for automated data collection
- Machine learning for bycatch prediction and reduction
- Carbon footprint tracking for sustainable operations
- International waters compliance monitoring
