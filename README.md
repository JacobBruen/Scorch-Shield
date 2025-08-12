# Scorch Shield

**CS4354 Final Project**  
Cameron Williams, David Poole, Stephan DeLuna, Jacob Bruen

---

## Overview

**Scorch Shield** is a database system built to modernize wildfire relief management by replacing outdated Excel-based systems. Wildfires require fast, coordinated action, yet many emergency systems lack the structured tools needed for that scale. This project improves communication, transparency, and speed by organizing relevant information into a normalized database with clearly defined relationships.

The full report of Scorch Shield can be downloaded via PDF and/or DOCX through this repository. 
---

## Team and Contributions

- **David Poole (Project Leader)** – Design section, Result analysis  
- **Cameron Williams (Project Manager)** – Testing and Implementation  
- **Stephan DeLuna (Query Developer)** – Introduction section  
- **Jacob Bruen (Database Designer)** – Final Database and Conclusion  

---

## Introduction

Wildfires in the U.S. have surged dramatically, with over 56,000 wildfires in 2022 alone. Our team developed a database to help fire management teams streamline data access and decisions. Key motivations included:

- Poor data access from legacy Excel sheets
- No centralized tracking of evacuees, shelters, or firefighters
- Need for faster allocation of aid and personnel

---

## Design

Our database includes the following entities:

- **Shelter**: Location, capacity, and population details
- **Firefighter**: Personnel assigned to wildfires
- **Wildfire**: Incident tracking, severity, containment
- **Evacuee**: Individuals housed in shelters
- **Aid**: Supplies provided to shelters
- **Donor**: Individuals or organizations donating aid

**Entity-Relationship Diagram (ERD)**  
![ER Diagram](Assets/ER-Diagram.png)


The design ensures:
- Every wildfire is tied to one location
- Shelters and evacuees are tracked separately
- Donors and aid records are linked for accountability
- Normalization is enforced to avoid redundancy

---

## Implementation

The system was implemented using **MySQL** and includes:

- DDL scripts to define schema and constraints
- Insert scripts with realistic test data
- Multiple complex queries for performance testing
- Exported CSV datasets for analysis

Features:
- Relationships: 1-to-many and many-to-many with junction tables
- Primary/foreign key integrity checks
- Views for high-level summaries

---

## System Testing & Query Examples

Example queries executed:

- Total number of active fires by state
- Aid received per shelter
- Top 3 donors by quantity
- Evacuees per shelter sorted by age

**Test Results:**
All queries returned expected results, and the schema held up under data validation tests. The system also successfully displayed summarized info through custom views.


---

## Conclusion

This project demonstrates how a relational database can transform disaster response. We started with a vague Excel-based system and restructured it into a robust, normalized schema that clearly outlines the relationships between shelters, evacuees, aid, donors, and firefighters.

While it’s a prototype, it lays the groundwork for a scalable system that could be expanded with:

- A web front-end interface
- Secure role-based access control
- Integration with GIS wildfire tracking tools

---

## How to Run the Project

This project includes:

- The SQL file (`project.sql`) to set up and populate the MySQL database for wildfire disaster relief.
- A Python script (`Disaster_Relief_Database_Queries.py`) that runs SQL queries and exports results to an Excel file.

### Step 1: Download the Files

Make sure you download both these files from this repository:

- `project.sql` — contains all SQL commands to create and populate the database.
- `Disaster_Relief_Database_Queries.py` — Python script to query the database and export results.

---

### Step 2: Set Up the MySQL Database

1. Install MySQL Community Server (https://dev.mysql.com/downloads/mysql/) if you don't have it installed.
2. Use MySQL Workbench or the MySQL command line to run the `project.sql` file and set up the database.

---

### Step 3: Run the Python Script

1. Install Python 3.x (https://www.python.org/downloads/) if not installed.
2. Install the required Python packages:

```bash
pip install mysql-connector-python pandas openpyxl

---

## Appendix

ERD and flowcharts are available in the `/assets` folder.

