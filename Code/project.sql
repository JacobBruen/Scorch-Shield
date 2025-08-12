-- 1) Drop & recreate database, then use it
DROP DATABASE IF EXISTS DisasterReliefDB;
CREATE DATABASE DisasterReliefDB
  CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
USE DisasterReliefDB;

-- 2) Create all tables
CREATE TABLE Shelter (
  Shelter_ID   VARCHAR(10)  NOT NULL PRIMARY KEY,
  Shelter_Name VARCHAR(100) NOT NULL,
  Capacity     INT,
  Location     VARCHAR(255),
  Contact      VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE Victim (
  Victim_ID   VARCHAR(10)  NOT NULL PRIMARY KEY,
  Victim_Name VARCHAR(100) NOT NULL,
  Age         INT,
  Location    VARCHAR(255),
  Shelter_ID  VARCHAR(10),
  FOREIGN KEY (Shelter_ID)
    REFERENCES Shelter(Shelter_ID)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Victim_Assistance_Needed (
  Victim_ID         VARCHAR(10)  NOT NULL,
  Assistance_Needed VARCHAR(100) NOT NULL,
  PRIMARY KEY (Victim_ID, Assistance_Needed),
  FOREIGN KEY (Victim_ID)
    REFERENCES Victim(Victim_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Volunteer (
  Volunteer_ID   VARCHAR(10)  NOT NULL PRIMARY KEY,
  Volunteer_Name VARCHAR(100) NOT NULL,
  Phone          VARCHAR(20),
  Availability   VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE Disaster (
  Disaster_ID   VARCHAR(10)  NOT NULL PRIMARY KEY,
  Disaster_Name VARCHAR(100),
  Location      VARCHAR(255),
  Severity      VARCHAR(50),
  Start_Date    DATE,
  End_Date      DATE,
  Volunteer_ID  VARCHAR(10),
  FOREIGN KEY (Volunteer_ID)
    REFERENCES Volunteer(Volunteer_ID)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Organization (
  Org_ID   VARCHAR(10)  NOT NULL PRIMARY KEY,
  Contact  VARCHAR(100),
  Org_Name VARCHAR(100) NOT NULL,
  Type     VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE Donation (
  Donation_ID VARCHAR(10)  NOT NULL PRIMARY KEY,
  Donor_Name  VARCHAR(100),
  Date        DATE,
  Type        VARCHAR(50),
  Amount      DECIMAL(12,2)
) ENGINE=InnoDB;

CREATE TABLE Resource (
  Resource_ID   VARCHAR(10)  NOT NULL PRIMARY KEY,
  Resource_Name VARCHAR(100),
  Status        VARCHAR(50),
  Amount      INT,
  Donation_ID   VARCHAR(10),
  Org_ID        VARCHAR(10),
  Request_ID    VARCHAR(10),
  FOREIGN KEY (Donation_ID)
    REFERENCES Donation(Donation_ID)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  FOREIGN KEY (Org_ID)
    REFERENCES Organization(Org_ID)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Aid_Request (
  Request_ID  VARCHAR(10)  NOT NULL PRIMARY KEY,
  Victim_ID   VARCHAR(10)  NOT NULL,
  Resource_ID VARCHAR(10)  NOT NULL,
  Status      VARCHAR(50),
  FOREIGN KEY (Victim_ID)
    REFERENCES Victim(Victim_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (Resource_ID)
    REFERENCES Resource(Resource_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

ALTER TABLE Resource
  ADD FOREIGN KEY (Request_ID)
    REFERENCES Aid_Request(Request_ID)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

CREATE TABLE Resource_Request (
  Resource_ID       VARCHAR(10)  NOT NULL,
  Request_ID        VARCHAR(10)  NOT NULL,
  Resource_Name     VARCHAR(50)  NOT NULL,
  PRIMARY KEY (Resource_ID, Request_ID),
  Amount int, 
  Status VARCHAR(50)  NOT NULL,

  FOREIGN KEY (Resource_ID)
    REFERENCES Resource(Resource_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  FOREIGN KEY (Request_ID)
    REFERENCES Aid_Request(Request_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

DELIMITER $$

-- 1) When a new request is inserted already as ‘Completed’
CREATE TRIGGER trg_rr_after_insert
AFTER INSERT ON Resource_Request
FOR EACH ROW
BEGIN
  IF NEW.Status = 'Completed' THEN
    UPDATE Resource
      SET Amount = Amount - NEW.Amount
    WHERE Resource_ID = NEW.Resource_ID;
  END IF;
END$$

-- 2) When an existing request changes status
CREATE TRIGGER trg_rr_after_update
AFTER UPDATE ON Resource_Request
FOR EACH ROW
BEGIN
  -- went TO Completed: deduct
  IF OLD.Status <> 'Completed' AND NEW.Status = 'Completed' THEN
    UPDATE Resource
      SET Amount = Amount - NEW.Amount
    WHERE Resource_ID = NEW.Resource_ID;
  END IF;
  -- left Completed: add back
  IF OLD.Status = 'Completed' AND NEW.Status <> 'Completed' THEN
    UPDATE Resource
      SET Amount = Amount + OLD.Amount
    WHERE Resource_ID = OLD.Resource_ID;
  END IF;
END$$

DELIMITER ;



CREATE TABLE Funds (
  Donation_ID VARCHAR(10) NOT NULL,
  Resource_ID VARCHAR(10) NOT NULL,
  PRIMARY KEY (Donation_ID, Resource_ID),
  FOREIGN KEY (Donation_ID)
    REFERENCES Donation(Donation_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Volunteer_Skills (
  Volunteer_ID    VARCHAR(10)  NOT NULL,
  Volunteer_Skill VARCHAR(100) NOT NULL,
  PRIMARY KEY (Volunteer_ID, Volunteer_Skill),
  FOREIGN KEY (Volunteer_ID)
    REFERENCES Volunteer(Volunteer_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Assists (
  Org_ID      VARCHAR(10) NOT NULL,
  Disaster_ID VARCHAR(10) NOT NULL,
  PRIMARY KEY (Org_ID, Disaster_ID),
  FOREIGN KEY (Org_ID)
    REFERENCES Organization(Org_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (Disaster_ID)
    REFERENCES Disaster(Disaster_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Uses (
  Volunteer_ID VARCHAR(10) NOT NULL,
  Resource_ID  VARCHAR(10) NOT NULL,
  PRIMARY KEY (Volunteer_ID, Resource_ID),
  FOREIGN KEY (Volunteer_ID)
    REFERENCES Volunteer(Volunteer_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (Resource_ID)
    REFERENCES Resource(Resource_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Disaster_Volunteer (
  Disaster_ID  VARCHAR(10) NOT NULL,
  Volunteer_ID VARCHAR(10) NOT NULL,
  PRIMARY KEY (Disaster_ID, Volunteer_ID),
  FOREIGN KEY (Disaster_ID)  REFERENCES Disaster(Disaster_ID)  ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (Volunteer_ID) REFERENCES Volunteer(Volunteer_ID) ON DELETE CASCADE ON UPDATE CASCADE
);


-- 3) Load sample data
SET FOREIGN_KEY_CHECKS = 0;

INSERT INTO Shelter (Shelter_ID, Shelter_Name, Capacity, Location, Contact) VALUES
(0102, 'Alabama Sanctuary of Care', 137, '1000 Compassion Way, Alabama, AL 38221', '(981) 555-1000'),(0103, 'Alabama Community Refuge', 136, '1001 Harmony St, Alabama, AL 59797', '(299) 555-1001'),
(0101, 'Alabama Caring Hands Shelter', 141, '1002 Rescue Blvd, Alabama, AL 44671', '(244) 555-1002'),(0202, 'Alaska Horizon Shelter', 167, '1003 Harmony St, Alaska, AK 59615', '(280) 555-1003'),
(0201, 'Alaska Bridge Shelter', 191, '1004 Rescue Blvd, Alaska, AK 57400', '(791) 555-1004'),(0203, 'Alaska Unity Shelter', 99, '1005 Harmony St, Alaska, AK 96673', '(433) 555-1005'),
(0302, 'Arizona Unity Shelter', 124, '1006 Compassion Way, Arizona, AZ 23238', '(589) 555-1006'),(0303, 'Arizona Lighthouse Refuge', 121, '1007 Shelter Rd, Arizona, AZ 31319', '(579) 555-1007'),
(0301, 'Arizona New Beginnings Home', 140, '1008 Shelter Rd, Arizona, AZ 99593', '(863) 555-1008'),(0403, 'Arkansas Hearth & Home', 68, '1009 Compassion Way, Arkansas, AR 80010', '(946) 555-1009'),
(0402, 'Arkansas Disaster Response Shelter', 112, '1010 Paw Ave, Arkansas, AR 59735', '(476) 555-1010'),(0401, 'Arkansas Rescue & Relief', 192, '1011 Shelter Rd, Arkansas, AR 17331', '(434) 555-1011'),
(0511, 'California Haven of Hope', 58, '1012 Paw Ave, California, CA 45093', '(267) 555-1012'),(0506, 'California Renewal Center', 104, '1013 Shelter Rd, California, CA 37869', '(871) 555-1013'),
(0502, 'California Oasis', 177, '1014 Paw Ave, California, CA 28726', '(471) 555-1014'),(0507, 'California Unity Shelter', 118, '1015 Rescue Blvd, California, CA 37653', '(935) 555-1015'),
(0504, 'California New Beginnings Home', 130, '1016 Paw Ave, California, CA 95909', '(605) 555-1016'),(0505, 'California Homeless Relief Center', 167, '1017 Compassion Way, California, CA 44718', '(452) 555-1017'),
(0509, 'California Lighthouse Refuge', 103, '1018 Harmony St, California, CA 93742', '(944) 555-1018'),(0510, 'California Bridge Shelter',  64, '1019 Shelter Rd, California, CA 99353', '(749) 555-1019'),
(0601, 'Colorado Community Refuge', 171, '1020 Harmony St, Colorado, CO 20223', '(353) 555-1020'),(0602, 'Colorado Harbor of Warmth', 166, '1021 Harmony St, Colorado, CO 14576', '(645) 555-1021'),
(0603, 'Colorado New Beginnings Home', 152, '1022 Rescue Blvd, Colorado, CO 82014', '(363) 555-1022'),(0604, 'Colorado Caring Hands Shelter', 130, '1023 Harmony St, Colorado, CO 20091', '(238) 555-1023'),
(0605, 'Colorado Oasis', 118, '1024 Compassion Way, Colorado, CO 17623', '(485) 555-1024'),(0606, 'Colorado Safe Harbor', 104, '1025 Shelter Rd, Colorado, CO 34906', '(544) 555-1025'),
(0701, 'Connecticut Hope Haven', 127, '1026 Shelter Rd, Connecticut, CT 46069', '(323) 555-1026'),(0801, 'Delaware Caring Hands Shelter', 160, '1027 Rescue Blvd, Delaware, DE 38842', '(856) 555-1027'),
(0902, 'Florida Oasis', 112, '1028 Harmony St, Florida, FL 91659', '(887) 555-1028'),(0905, 'Florida Family Shelter', 198, '1029 Rescue Blvd, Florida, FL 48320', '(502) 555-1029'),
(0901, 'Florida Bridge Shelter', 129, '1030 Shelter Rd, Florida, FL 22409', '(563) 555-1030'),(0903, 'Florida Sanctuary of Care',  94, '1031 Compassion Way, Florida, FL 35094', '(481) 555-1031'),(0904, 'Florida New Beginnings Home', 74, '1032 Paw Ave, Florida, FL 73815', '(455) 555-1032'),
(1001, 'Georgia Harbor of Warmth', 173, '1033 Paw Ave, Georgia, GA 62680', '(505) 555-1033'),(1002, 'Georgia Caring Hands Shelter',  62, '1034 Harmony St, Georgia, GA 64915', '(972) 555-1034'),
(1003, 'Georgia Oasis', 55,  '1035 Rescue Blvd, Georgia, GA 73702', '(529) 555-1035'),(1004, 'Georgia Homeless Relief Center', 75, '1036 Harmony St, Georgia, GA 73564', '(769) 555-1036'),
(1101, 'Hawaii Hope Haven', 146, '1037 Harmony St, Hawaii, HI 10017', '(661) 555-1037'),(1202, 'Idaho Sanctuary of Care', 191, '1038 Harmony St, Idaho, ID 29124', '(500) 555-1038'),
(1201, 'Idaho Bridge Shelter', 78,  '1039 Rescue Blvd, Idaho, ID 30038', '(276) 555-1039'),(1301, 'Illinois Lighthouse Refuge', 189, '1040 Harmony St, Illinois, IL 76529', '(714) 555-1040'),
(1302, 'Illinois Rescue & Relief', 174, '1041 Compassion Way, Illinois, IL 47426', '(614) 555-1041'),(1303, 'Illinois Community Refuge', 164, '1042 Rescue Blvd, Illinois, IL 36132', '(620) 555-1042'),
(1304, 'Illinois Caring Hands Shelter', 151, '1043 Harmony St, Illinois, IL 99138', '(210) 555-1043'),(1305, 'Illinois Safe Harbor', 157, '1044 Shelter Rd, Illinois, IL 18910', '(443) 555-1044'),
(1401, 'Indiana New Beginnings Home', 164, '1045 Shelter Rd, Indiana, IN 59232', '(841) 555-1045'),(1501, 'Iowa Hope Haven', 173, '1046 Shelter Rd, Iowa, IA 51267', '(914) 555-1046'),
(1601, 'Kansas Bridge Shelter', 194, '1047 Paw Ave, Kansas, KS 88476', '(808) 555-1047'),(1602, 'Kansas Community Refuge', 120, '1048 Harmony St, Kansas, KS 45938', '(420) 555-1048'),
(1603, 'Kansas Rescue & Relief', 107, '1049 Shelter Rd, Kansas, KS 57421', '(236) 555-1049'),(1604, 'Kansas Caring Hands Shelter', 88,  '1050 Rescue Blvd, Kansas, KS 91328', '(983) 555-1050'),
(1605, 'Kansas Oasis', 82,  '1051 Compassion Way, Kansas, KS 35949', '(612) 555-1051'),(1606, 'Kansas Family Shelter', 80,  '1052 Rescue Blvd, Kansas, KS 33290', '(713) 555-1052'),
(1607, 'Kansas Sanctuary of Care', 94,  '1053 Harmony St, Kansas, KS 98013', '(559) 555-1053'),(1608, 'Kansas Homeless Relief Center', 69, '1054 Paw Ave, Kansas, KS 87284', '(760) 555-1054'),
(1701, 'Kentucky Hearth & Home', 187, '1055 Paw Ave, Kentucky, KY 63217', '(418) 555-1055'),(1702, 'Kentucky Caring Hands Shelter', 178, '1056 Harmony St, Kentucky, KY 51538', '(275) 555-1056'),
(1703, 'Kentucky Community Refuge', 162, '1057 Rescue Blvd, Kentucky, KY 20726', '(379) 555-1057'),(1704, 'Kentucky Renewal Center', 153, '1058 Harmony St, Kentucky, KY 38961', '(584) 555-1058'),
(1705, 'Kentucky Oasis', 129, '1059 Compassion Way, Kentucky, KY 79014', '(767) 555-1059'),(1706, 'Kentucky Lighthouse Refuge', 116, '1060 Shelter Rd, Kentucky, KY 38961', '(584) 555-1060'),
(1707, 'Kentucky Safe Harbor', 64,  '1061 Paw Ave, Kentucky, KY 78403', '(579) 555-1061'),(1801, 'Louisiana Rescue & Relief', 195, '1062 Shelter Rd, Louisiana, LA 37325', '(339) 555-1062'),
(1802, 'Louisiana Community Refuge', 149, '1063 Paw Ave, Louisiana, LA 17046', '(740) 555-1063'),(1803, 'Louisiana Oasis', 83,  '1064 Rescue Blvd, Louisiana, LA 55831', '(981) 555-1064'),
(1804, 'Louisiana Hope Haven', 74,  '1065 Harmony St, Louisiana, LA 60541', '(734) 555-1065'),(1901, 'Maine Lighthouse Refuge', 146, '1066 Harmony St, Maine, ME 69103', '(902) 555-1066'),
(1902, 'Maryland Rescue & Relief', 198, '1067 Compassion Way, Maryland, MD 61027', '(276) 555-1067'),(2001, 'Massachusetts Hope Haven', 127, '1068 Harmony St, Massachusetts, MA 54163', '(562) 555-1068'),
(2101, 'Michigan Disaster Response Shelter', 194, '1069 Harmony St, Michigan, MI 40719', '(654) 555-1069'),(2201, 'Minnesota Oasis', 86,  '1070 Paw Ave, Minnesota, MN 55790', '(250) 555-1070'),
(2301, 'Mississippi Homeless Relief Center', 162, '1071 Shelter Rd, Mississippi, MS 24246', '(239) 555-1071'),(2401, 'Missouri Unity Shelter', 180, '1072 Compassion Way, Missouri, MO 85886', '(415) 555-1072'),
(2501, 'Montana Sanctuary of Care', 128, '1073 Harmony St, Montana, MT 82346', '(285) 555-1073'),(2601, 'Nebraska Oasis', 71,  '1074 Shelter Rd, Nebraska, NE 77561', '(543) 555-1074'),
(2701, 'Nevada Bridge Shelter', 189, '1075 Paw Ave, Nevada, NV 40091', '(312) 555-1075'),(2801, 'New Hampshire Caring Hands Shelter', 117, '1076 Harmony St, New Hampshire, NH 53101', '(492) 555-1076'),
(2901, 'New Jersey Rescue & Relief', 79,  '1077 Rescue Blvd, New Jersey, NJ 93590', '(693) 555-1077'),(3001, 'New Mexico Family Shelter', 114, '1078 Shelter Rd, New Mexico, NM 88042', '(954) 555-1078'),
(3101, 'New York Renewal Center', 135, '1079 Harmony St, New York, NY 97806', '(952) 555-1079'),(3102, 'New York Caring Hands Shelter', 113, '1080 Rescue Blvd, New York, NY 30866', '(918) 555-1080'),
(3103, 'New York Homeless Relief Center', 77, '1081 Harmony St, New York, NY 15075', '(681) 555-1081'),(3201, 'North Carolina Hope Haven', 128, '1082 Paw Ave, North Carolina, NC 39219', '(224) 555-1082'),
(3202, 'North Carolina Oasis', 106, '1083 Paw Ave, North Carolina, NC 70332', '(558) 555-1083'),(3301, 'North Dakota Family Shelter', 180, '1084 Rescue Blvd, North Dakota, ND 56025', '(749) 555-1084'),
(3302, 'North Dakota Caring Hands Shelter', 67, '1085 Compassion Way, North Dakota, ND 56025', '(856) 555-1085'),(3401, 'Ohio Safe Harbor', 95,  '1086 Compassion Way, Ohio, OH 44795', '(239) 555-1086'),(3501, 'Oklahoma Oasis', 77,  '1087 Compassion Way, Oklahoma, OK 66959', '(553) 555-1087'),
(3502, 'Oklahoma Caring Hands Shelter', 130, '1088 Harmony St, Oklahoma, OK 89457', '(723) 555-1088'),(3601, 'Oregon Oasis', 79,  '1089 Harmony St, Oregon, OR 85574', '(394) 555-1089'),
(3701, 'Pennsylvania Caring Hands Shelter', 115, '1090 Shelter Rd, Pennsylvania, PA 67154', '(201) 555-1090'),(3801, 'Rhode Island Hope Haven', 165, '1091 Harmony St, Rhode Island, RI 43210', '(512) 555-1091'),
(3901, 'South Carolina Lighthouse Refuge', 178, '1092 Rescue Blvd, South Carolina, SC 15983', '(713) 555-1092'),(4001, 'South Dakota Bridge Shelter', 142, '1093 Rescue Blvd, South Dakota, SD 84736', '(309) 555-1093'),
(4101, 'Tennessee Harbor of Warmth', 187, '1094 Harmony St, Tennessee, TN 54781', '(467) 555-1094'),(4301, 'Texas Community Refuge', 180, '1095 Paw Ave, Texas, TX 31620', '(394) 555-1095'),
(4302, 'Texas Caring Hands Shelter', 161, '1096 Shelter Rd, Texas, TX 18592', '(820) 555-1096'),(4303, 'Texas Safe Harbor', 115, '1097 Compassion Way, Texas, TX 43958', '(732) 555-1097'),
(4304, 'Texas Renewal Center', 95, '1098 Harmony St, Texas, TX 78904', '(311) 555-1098'),(4401, 'Utah New Beginnings Home', 187, '1099 Paw Ave, Utah, UT 96842', '(271) 555-1099'),
(4501, 'Vermont Hearth & Home', 134, '1100 Shelter Rd, Vermont, VT 23645', '(327) 555-1100'),(4502, 'Vermont Harbor of Warmth', 126, '1101 Shelter Rd, Vermont, VT 65162', '(618) 555-1101'),
(4601, 'Virginia Oasis', 133, '1102 Harmony St, Virginia, VA 29031', '(330) 555-1102'),(4602, 'Virginia Ember Shelter', 99, '1103 Paw Ave, Virginia, VA 41579', '(966) 555-1103'),
(4701, 'Washington Hope Haven', 190, '1104 Shelter Rd, Washington, WA 68319', '(415) 555-1104'),(4702, 'Washington Hearth & Home', 94, '1105 Rescue Blvd, Washington, WA 25063', '(615) 555-1105'),
(4801, 'West Virginia Renewal Center', 160, '1106 Rescue Blvd, West Virginia, WV 56920', '(529) 555-1106'),(4901, 'Wisconsin Lighthouse Refuge', 169, '1107 Paw Ave, Wisconsin, WI 30479', '(418) 555-1107'),(5001, 'Wyoming Family Shelter', 180, '1108 Compassion Way, Wyoming, WY 18647', '(286) 555-1108');

INSERT INTO Victim (Victim_ID, Victim_Name, Age, Location, Shelter_ID) VALUES
('010001', 'James Smith', 22, '1000 Compassion Way, Alabama, AL 38221', '0101'),('010002', 'Mary Johnson', 35, '1000 Compassion Way, Alabama, AL 38221', '0101'),('010003', 'Linda Davis', 47, '1000 Compassion Way, Alabama, AL 38221', '0101'),('020001', 'Patricia Brown', 34, '1003 Harmony St, Alaska, AK 59615', '0201'),
('020002', 'Michael Smith', 29, '1003 Harmony St, Alaska, AK 59615', '0201'),('020003', 'Elizabeth Davis', 58, '1003 Harmony St, Alaska, AK 59615', '0201'),('020004', 'John White', 10, '1004 Rescue Blvd, Alaska, AK 57400', '0202'),('020005', 'Jennifer Hernandez', 58, '1004 Rescue Blvd, Alaska, AK 57400', '0202'),
('020006', 'Robert Martinez', 41, '1005 Harmony St, Alaska, AK 96673', '0203'),('030001', 'Thomas Clark', 55, '1006 Shelter Rd, Arizona, AZ 23238', '0301'),('030002', 'Sarah Lewis', 18, '1006 Shelter Rd, Arizona, AZ 23238', '0301'),('030003', 'Christopher Hall', 82, '1006 Shelter Rd, Arizona, AZ 23238', '0301'),
('030004', 'Karen Young', 39, '1007 Shelter Rd, Arizona, AZ 99593', '0302'),('030005', 'Daniel King', 31, '1007 Shelter Rd, Arizona, AZ 99593', '0302'),('030006', 'Nancy Scott', 47, '1008 Shelter Rd, Arizona, AZ 31319', '0303'),('040001', 'Matthew Perez', 64, '1009 Compassion Way, Arkansas, AR 80010', '0401'),
('040002', 'Betty Wright', 82, '1009 Compassion Way, Arkansas, AR 80010', '0401'),('040003', 'Anthony Torres', 18, '1010 Paw Ave, Arkansas, AR 59735', '0402'),('040004', 'Dorothy Nguyen', 20, '1010 Paw Ave, Arkansas, AR 59735', '0402'),('040005', 'Steven Hill', 26, '1011 Shelter Rd, Arkansas, AR 17331', '0403'),
('050001', 'Donna Adams', 49, '1012 Paw Ave, California, CA 45093', '0501'),('050002', 'Kenneth Baker', 10, '1012 Paw Ave, California, CA 45093', '0501'),('050003', 'Carol Hall', 58, '1012 Paw Ave, California, CA 45093', '0501'),('050004', 'Brian Rivera', 32, '1013 Shelter Rd, California, CA 37869', '0502'),
('050005', 'Michelle Carter', 56, '1013 Shelter Rd, California, CA 37869', '0502'),('050006', 'Edward Mitchell', 64, '1014 Paw Ave, California, CA 28726', '0503'),('050007', 'Amanda Roberts', 82, '1014 Paw Ave, California, CA 28726', '0503'),('050008', 'George Thompson', 18, '1015 Rescue Blvd, California, CA 37653', '0504'),
('050009', 'Melissa Lopez', 39, '1015 Rescue Blvd, California, CA 37653', '0504'),('050010', 'Donald Brown', 31, '1016 Paw Ave, California, CA 59735', '0510'),('050011', 'Joshua Torres', 47, '1017 Harmony St, California, CA 59304', '0506'),('050012', 'Richard Thomas', 15, '1018 Rescue Blvd, California, CA 21547', '0507'),
('050013', 'Melissa Johnson', 73, '1019 Shelter Rd, California, CA 90736', '0508'),('050014', 'Donald Allen', 26, '1020 Paw Ave, California, CA 24697', '0511'),('050015', 'David Carter', 54, '1021 Harmony St, California, CA 46281', '0512'),('050016', 'Sandra Harris', 36, '1022 Rescue Blvd, California, CA 54829', '0509'),
('050017', 'Mark Sanchez', 89, '1023 Shelter Rd, California, CA 19635', '0505'),('050018', 'Patricia Clark', 42, '1024 Compassion Way, California, CA 75489', '0513'),('050019', 'James Lewis', 75, '1025 Harmony St, California, CA 40527', '0514'),('050020', 'Elizabeth Martinez', 67, '1026 Paw Ave, California, CA 63045', '0515'),
('050021', 'Charles Lee', 11, '1027 Rescue Blvd, California, CA 50380', '0504'),('050022', 'Michael Robinson', 58, '1028 Harmony St, California, CA 29613', '0503'),('050023', 'Karen Walker', 21, '1029 Shelter Rd, California, CA 72019', '0502'),('050024', 'Joseph Young', 34, '1030 Paw Ave, California, CA 15437', '0501'),
('050025', 'Lisa King', 49, '1031 Compassion Way, California, CA 32718', '0516'),('050026', 'Christopher Wright', 60, '1032 Harmony St, California, CA 41592', '0517'),('050027', 'Nancy Hill', 88, '1033 Shelter Rd, California, CA 37205', '0508'),('050028', 'James Mitchell', 54, '1015 Rescue Blvd, California, CA 42087', '0509'),
('050029', 'Matthew Nguyen',  5, '1021 Shelter Rd, California, CA 37869', '0501'),('050030', 'Susan Mitchell', 36, '1010 Harmony St, California, CA 59823', '0502'),('060001', 'Kenneth Lopez', 29, '1097 Harmony St, Colorado, CO 70068', '0601'),('060002', 'Joseph Williams', 69, '1081 Compassion Way, Colorado, CO 34890', '0606'),
('060352', 'Grant Williams', 33, '1081 Compassion Way, Colorado, CO 34890', '0606'),('069459', 'Scarlett Taylor', 60, '1020 Harmony St, Colorado, CO 20223', '0601'),('066227', 'James White', 35, '1020 Harmony St, Colorado, CO 20223', '0601'),('064741', 'Amelia Anderson', 82, '1020 Harmony St, Colorado, CO 20223', '0601'),
('066201', 'Jayden Taylor', 89, '1020 Harmony St, Colorado, CO 20223', '0601'),('063432', 'Emma Smith', 42, '1021 Harmony St, Colorado, CO 14576', '0602'),('064010', 'Oliver Jackson', 8, '1021 Harmony St, Colorado, CO 14576', '0602'),('064554', 'Amelia Lewis', 30, '1022 Rescue Blvd, Colorado, CO 82014', '0603'),
('061307', 'Aria Smith', 5, '1022 Rescue Blvd, Colorado, CO 82014', '0603'),('061139', 'Carter Jackson', 41, '1022 Rescue Blvd, Colorado, CO 82014', '0603'),('065820', 'Luke Allen', 52, '1022 Rescue Blvd, Colorado, CO 82014', '0603'),('068751', 'Layla Lee', 35, '1022 Rescue Blvd, Colorado, CO 82014', '0603'),
('063733', 'Elizabeth White', 9, '1023 Harmony St, Colorado, CO 20091', '0604'),('061169', 'Camila Walker', 28, '1023 Harmony St, Colorado, CO 20091', '0604'),('060750', 'James Torres', 73, '1023 Harmony St, Colorado, CO 20091', '0604'),('065925', 'Olivia Scott', 41, '1023 Harmony St, Colorado, CO 20091', '0604'),
('061654', 'Mia King', 28, '1023 Harmony St, Colorado, CO 20091', '0604'),('065977', 'Matthew Thompson', 84, '1024 Compassion Way, Colorado, CO 17623', '0605'),('062664', 'James Anderson', 64, '1024 Compassion Way, Colorado, CO 17623', '0605'),('066065', 'Jackson Taylor', 83, '1024 Compassion Way, Colorado, CO 17623', '0605'),
('063814', 'Oliver Martinez', 59, '1024 Compassion Way, Colorado, CO 17623', '0605'),('063150', 'Sophia Garcia', 19, '1025 Shelter Rd, Colorado, CO 34906', '0606'),('062045', 'Emily Hall', 34, '1025 Shelter Rd, Colorado, CO 34906', '0606'),('069044', 'Harper Torres', 18, '1025 Shelter Rd, Colorado, CO 34906', '0606'),
('067428', 'Emma Wright', 32, '1025 Shelter Rd, Colorado, CO 34906', '0606'),('061291', 'Samuel Lee', 72, '1025 Shelter Rd, Colorado, CO 34906', '0606'),('071674', 'Daisy Scott', 69, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),('075514', 'Isaac Garcia', 16, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),('074552', 'Hannah Diaz', 49, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),('071519', 'Daisy Reed', 11, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),
('070711', 'Caleb Stewart', 71, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),('073527', 'Nora Adams', 38, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),('071584', 'Aiden Bennett', 81, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),('075635', 'Gavin Garcia', 80, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),
('076224', 'Quinn Turner', 47, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),('077527', 'Aiden Reed', 74, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),('079891', 'Gavin Reed', 25, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),('072547', 'Nora Garcia', 9, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),
('074333', 'Owen Stewart', 6, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),('075881', 'Isaac Scott', 85, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),('075574', 'Fiona Morgan', 30, '1026 Shelter Rd, Connecticut, CT 46069', '0701'),('081535', 'Leo Brooks', 30, '1027 Rescue Blvd, Delaware, DE 38842', '0801'),
('086912', 'Jack Ivey', 65, '1027 Rescue Blvd, Delaware, DE 38842', '0801'),('080520', 'Avery Fitzgerald', 78, '1027 Rescue Blvd, Delaware, DE 38842', '0801'),('083582', 'Leo Taylor', 4, '1027 Rescue Blvd, Delaware, DE 38842', '0801'),('080488', 'Chloe Underwood', 72, '1027 Rescue Blvd, Delaware, DE 38842', '0801'),
('099891', 'Caleb Morgan', 13, '1028 Harmony St, Florida, FL 91659', '0902'),('096201', 'Zachary Bennett', 49, '1028 Harmony St, Florida, FL 91659', '0902'),('095881', 'Evan Bailey', 36, '1028 Harmony St, Florida, FL 91659', '0902'),('092045', 'Chloe Bell', 59, '1028 Harmony St, Florida, FL 91659', '0902'),
('091584', 'Avery Morgan', 82, '1028 Harmony St, Florida, FL 91659', '0902'),('091674', 'Grace Bennett', 47, '1029 Rescue Blvd, Florida, FL 48320', '0905'),('097527', 'Cole James', 21, '1029 Rescue Blvd, Florida, FL 48320', '0905'),('094333', 'Connor Watson', 48, '1029 Rescue Blvd, Florida, FL 48320', '0905'),
('099459', 'Sydney Reed', 46, '1029 Rescue Blvd, Florida, FL 48320', '0905'),('091519', 'Zachary Cook', 27, '1029 Rescue Blvd, Florida, FL 48320', '0905'),('095635', 'Dylan Bailey', 86, '1030 Shelter Rd, Florida, FL 22409', '0901'),('094741', 'Logan Brooks', 35, '1030 Shelter Rd, Florida, FL 22409', '0901'),
('094803', 'Zachary James', 90, '1030 Shelter Rd, Florida, FL 22409', '0901'),('091139', 'Dylan Price', 88, '1030 Shelter Rd, Florida, FL 22409', '0901'),('090711', 'Caleb Price', 83, '1030 Shelter Rd, Florida, FL 22409', '0901'),('093814', 'Alyssa Torres', 10, '1031 Compassion Way, Florida, FL 35094', '0903'),
('099044', 'Chloe Peterson', 78, '1031 Compassion Way, Florida, FL 35094', '0903'),('093150', 'Brandon Cooper', 82, '1031 Compassion Way, Florida, FL 35094', '0903'),('096224', 'Aubrey Foster', 22, '1031 Compassion Way, Florida, FL 35094', '0903'),('098785', 'Zachary Wood', 69, '1031 Compassion Way, Florida, FL 35094', '0903'),
('095925', 'Aubrey Murphy', 32, '1032 Paw Ave, Florida, FL 73815', '0904'),('093733', 'Eli Torres', 21, '1032 Paw Ave, Florida, FL 73815', '0904'),('090750', 'Gavin Cooper', 60, '1032 Paw Ave, Florida, FL 73815', '0904'),('091291', 'Blake Collins', 49, '1032 Paw Ave, Florida, FL 73815', '0904'),
('091307', 'Kyle Cox', 35, '1032 Paw Ave, Florida, FL 73815', '0904'),('100054', 'Jennifer Hernandez', 82, '1035 Harmony St, Georgia, GA 48469', '1002'),('100055', 'Robert Baker', 63, '1035 Harmony St, Georgia, GA 48469', '1002'),('090001', 'Donald Thomas', 74, '1033 Harmony St, Florida, FL 99166', '0901'),
('090002', 'David Carter', 32, '1033 Harmony St, Florida, FL 99166', '0901'),('090003', 'Sandra Anderson', 42, '1033 Harmony St, Florida, FL 99166', '0901'),('090004', 'Michael Nelson', 49, '1033 Harmony St, Florida, FL 99166', '0901'),('090005', 'Emily Flores', 36, '1033 Harmony St, Florida, FL 99166', '0901'),
('090006', 'Michael Martin', 51, '1033 Harmony St, Florida, FL 99166', '0901'),('100001', 'James Martin', 72, '1029 Paw Ave, Georgia, GA 62680', '1001'),('100002', 'Linda Johnson', 27, '1029 Paw Ave, Georgia, GA 62680', '1001'),('100003', 'Robert Brown', 33, '1029 Paw Ave, Georgia, GA 62680', '1001'),
('100004', 'Patricia Williams', 45, '1029 Paw Ave, Georgia, GA 62680', '1001'),('100005', 'Michael Davis', 19, '1029 Paw Ave, Georgia, GA 62680', '1001'),('110625', 'Kai Kama', 72,  '1037 Harmony St, Hawaii, HI 10017', '1101'),('118785', 'Kona Pena', 43, '1037 Harmony St, Hawaii, HI 10017', '1101'),
('114367', 'Leilani Pacheco', 44, '1037 Harmony St, Hawaii, HI 10017', '1101'),('116211', 'Anela Kalani', 7,  '1037 Harmony St, Hawaii, HI 10017', '1101'),('111764', 'Keanu Lokahi', 21, '1037 Harmony St, Hawaii, HI 10017', '1101'),('120845', 'Asher Reed', 29, '1038 Harmony St, Idaho, ID 29124', '1202'),
('121379', 'Ella Morgan', 54, '1038 Harmony St, Idaho, ID 29124', '1202'),('122014', 'Caleb Davis', 38, '1038 Harmony St, Idaho, ID 29124', '1202'),('128501', 'Mila Thompson', 16, '1039 Rescue Blvd, Idaho, ID 30038', '1201'),('125763', 'Eli Cooper', 47, '1039 Rescue Blvd, Idaho, ID 30038', '1201'),
('120992', 'Zoe Hill', 67, '1039 Rescue Blvd, Idaho, ID 30038', '1201'),('130488', 'Logan Green', 36, '1040 Harmony St, Illinois, IL 76529', '1301'),('137359', 'Liam Parker', 1,  '1040 Harmony St, Illinois, IL 76529', '1301'),('139863', 'Ethan Ramirez', 21, '1040 Harmony St, Illinois, IL 76529', '1301'),
('138928', 'Alexander Edwards', 90, '1041 Compassion Way, Illinois, IL 47426', '1302'),('138279', 'Sophia Anderson', 55, '1041 Compassion Way, Illinois, IL 47426', '1302'),('133811', 'Elijah King', 44, '1041 Compassion Way, Illinois, IL 47426', '1302'),('130520', 'Ava Evans', 36, '1042 Rescue Blvd, Illinois, IL 36132', '1303'),
('133611', 'Emma Hill', 20, '1042 Rescue Blvd, Illinois, IL 36132', '1303'),('133582', 'Alexander Parker', 28, '1042 Rescue Blvd, Illinois, IL 36132', '1303'),('139654', 'Liam Ramirez', 44, '1043 Harmony St, Illinois, IL 99138', '1304'),('133257', 'Evelyn Scott', 14, '1043 Harmony St, Illinois, IL 99138', '1304'),('131535', 'Amelia Edwards', 12, '1043 Harmony St, Illinois, IL 99138', '1304'),
('139195', 'Liam Young', 49, '1044 Shelter Rd, Illinois, IL 18910', '1305'),('130434', 'Harper Wright', 13, '1044 Shelter Rd, Illinois, IL 18910', '1305'),('136873', 'Benjamin Torres', 46, '1044 Shelter Rd, Illinois, IL 18910', '1305'),('140027', 'Oliver Evans', 1,  '1045 Shelter Rd, Indiana, IN 59232', '1401'),
('142615', 'Charlotte Foster', 41, '1045 Shelter Rd, Indiana, IN 59232', '1401'),('145524', 'Jack Parker', 58,    '1045 Shelter Rd, Indiana, IN 59232', '1401'),('151144', 'Oliver Foster', 14,  '1046 Shelter Rd, Iowa, IA 51267',    '1501'),('151435', 'Elijah Scott', 6,    '1046 Shelter Rd, Iowa, IA 51267',    '1501'),
('154016', 'Evelyn Brooks', 12,  '1046 Shelter Rd, Iowa, IA 51267',    '1501'),('164133', 'George Quinn', 84, '1047 Paw Ave, Kansas, KS 88476', '1601'),('167564', 'Ulysses Foster', 6, '1047 Paw Ave, Kansas, KS 88476', '1601'),('162223', 'Xena Lopez', 4, '1047 Paw Ave, Kansas, KS 88476', '1601'),
('165733', 'Ethan O''Brien', 32, '1048 Harmony St, Kansas, KS 45938', '1602'),('167449', 'Bob Quinn', 26, '1048 Harmony St, Kansas, KS 45938', '1602'),('164558', 'Nina Vargas', 3, '1048 Harmony St, Kansas, KS 45938', '1602'),('163467', 'Paula Foster', 80, '1049 Shelter Rd, Kansas, KS 57421', '1603'),
('160853', 'Mark Armstrong', 20, '1049 Shelter Rd, Kansas, KS 57421', '1603'),('165355', 'Alice Clark', 31, '1049 Shelter Rd, Kansas, KS 57421', '1603'),('167705', 'Tina Quinn', 17, '1050 Rescue Blvd, Kansas, KS 91328', '1604'),('167022', 'Hannah Clark', 61, '1050 Rescue Blvd, Kansas, KS 91328', '1604'),
('163673', 'Steve Vargas', 86, '1050 Rescue Blvd, Kansas, KS 91328', '1604'),('161341', 'Hannah Diaz', 15, '1051 Compassion Way, Kansas, KS 35949', '1605'),('165529', 'Wayne Morris', 73, '1051 Compassion Way, Kansas, KS 35949', '1605'),('160823', 'Fiona Garcia', 28, '1051 Compassion Way, Kansas, KS 35949', '1605'),
('161124', 'Mark O''Brien', 60, '1052 Rescue Blvd, Kansas, KS 33290', '1606'),('166211', 'Ian White', 90, '1052 Rescue Blvd, Kansas, KS 33290', '1606'),('164262', 'Violet O''Brien', 33, '1052 Rescue Blvd, Kansas, KS 33290', '1606'),('166906', 'Ulysses Armstrong', 48, '1053 Harmony St, Kansas, KS 98013', '1607'),
('160317', 'Rachel O''Brien', 22, '1053 Harmony St, Kansas, KS 98013', '1607'),('162977', 'Paula Quinn', 78, '1053 Harmony St, Kansas, KS 98013', '1607'),('161375', 'George Vargas', 78, '1054 Paw Ave, Kansas, KS 87284', '1608'),('165363', 'Owen Reed', 15, '1054 Paw Ave, Kansas, KS 87284', '1608'),
('168837', 'Fiona Ivanov', 21, '1054 Paw Ave, Kansas, KS 87284', '1608'),('175313', 'Isabella Smith', 33, '1055 Paw Ave, Kentucky, KY 63217', '1701'),('173814', 'Abigail Davis', 71, '1055 Paw Ave, Kentucky, KY 63217', '1701'),('174374', 'James Jones', 2,  '1055 Paw Ave, Kentucky, KY 63217', '1701'),
('171796', 'Elijah Perez', 88, '1056 Harmony St, Kentucky, KY 51538', '1702'),('179197', 'Owen Williams', 15, '1056 Harmony St, Kentucky, KY 51538', '1702'),('172621', 'Chloe Wilson', 88, '1056 Harmony St, Kentucky, KY 51538', '1702'),('172677', 'Liam Smith', 69, '1057 Rescue Blvd, Kentucky, KY 20726', '1703'),
('173456', 'Sophia Miller', 35, '1057 Rescue Blvd, Kentucky, KY 20726', '1703'),('172266', 'James Taylor', 83, '1057 Rescue Blvd, Kentucky, KY 20726', '1703'),('173752', 'Matthew Smith', 44, '1058 Harmony St, Kentucky, KY 38961', '1704'),('174741', 'Grace Miller', 15, '1058 Harmony St, Kentucky, KY 38961', '1704'),
('176227', 'Owen Wilson', 38, '1058 Harmony St, Kentucky, KY 38961', '1704'),('175168', 'James Anderson', 56, '1059 Compassion Way, Kentucky, KY 79014', '1705'),('176304', 'Chloe Rodriguez', 21, '1059 Compassion Way, Kentucky, KY 79014', '1705'),('178751', 'Oliver Harris', 59, '1059 Compassion Way, Kentucky, KY 79014', '1705'),
('174889', 'Emily Brown', 82, '1061 Paw Ave, Kentucky, KY 78403', '1707'),('171743', 'Harper Harris', 81, '1061 Paw Ave, Kentucky, KY 78403', '1707'),('178317', 'Sophia Gonzalez', 78, '1061 Paw Ave, Kentucky, KY 78403', '1707'),('183258', 'Elijah Lopez', 20, '1062 Shelter Rd, Louisiana, LA 37325', '1801'),
('186126', 'Michael Martin', 21, '1062 Shelter Rd, Louisiana, LA 37325', '1801'),('188837', 'Logan Sanchez', 68, '1062 Shelter Rd, Louisiana, LA 37325', '1801'),('180009', 'Liam White', 77, '1063 Paw Ave, Louisiana, LA 17046', '1802'),('185310', 'Victoria Moore', 63, '1063 Paw Ave, Louisiana, LA 17046', '1802'),
('180319', 'Isabella Robinson', 15, '1063 Paw Ave, Louisiana, LA 17046', '1802'),('185947', 'Alexander Williams', 40, '1064 Rescue Blvd, Louisiana, LA 55831', '1803'),('183923', 'Grace Martinez', 8, '1064 Rescue Blvd, Louisiana, LA 55831', '1803'),('183946', 'Camila Lewis', 73, '1064 Rescue Blvd, Louisiana, LA 55831', '1803'),
('181290', 'Elizabeth Jackson', 11, '1065 Harmony St, Louisiana, LA 60541', '1804'),('187962', 'Ethan Thompson', 9, '1065 Harmony St, Louisiana, LA 60541', '1804'),('188727', 'Noah Johnson', 17, '1065 Harmony St, Louisiana, LA 60541', '1804'),('190001', 'Henry Stewart', 45, '1066 Harmony St, Maine, ME 69103', '1901'),
('190002', 'Abigail King', 9, '1066 Harmony St, Maine, ME 69103', '1901'),('190003', 'John Ramirez', 32, '1066 Harmony St, Maine, ME 69103', '1901'),('190004', 'Ella Flores', 48, '1066 Harmony St, Maine, ME 69103', '1901'),('190005', 'Madison Mitchell', 37, '1066 Harmony St, Maine, ME 69103', '1901'),('190006', 'Wyatt Gutierrez', 21, '1067 Compassion Way, Maryland, MD 61027', '1902'),('190007', 'Nora Thomas', 57, '1067 Compassion Way, Maryland, MD 61027', '1902'),
('190008', 'Luna Lewis', 70, '1067 Compassion Way, Maryland, MD 61027', '1902'),('190009', 'William Baker', 39, '1067 Compassion Way, Maryland, MD 61027', '1902'),('190010', 'Noah Robinson', 79, '1067 Compassion Way, Maryland, MD 61027', '1902'),('200001', 'Jacob Smith', 84, '1068 Harmony St, Massachusetts, MA 54163', '2001'),
('200002', 'Isabella Davis', 68, '1068 Harmony St, Massachusetts, MA 54163', '2001'),('200003', 'Camila Rodriguez', 2, '1068 Harmony St, Massachusetts, MA 54163', '2001'),('200004', 'Oliver Nelson', 86, '1068 Harmony St, Massachusetts, MA 54163', '2001'),('200005', 'Isabella Rogers', 71, '1068 Harmony St, Massachusetts, MA 54163', '2001'),
('210001', 'Logan Scott', 39, '1069 Harmony St, Michigan, MI 40719', '2101'),('210002', 'Luke Ramirez', 85, '1069 Harmony St, Michigan, MI 40719', '2101'),('210003', 'Luna Stewart', 14, '1069 Harmony St, Michigan, MI 40719', '2101'),('210004', 'David Harris', 18, '1069 Harmony St, Michigan, MI 40719', '2101'),
('210005', 'Benjamin Gonzalez', 34, '1069 Harmony St, Michigan, MI 40719', '2101'),('220001', 'Grace Rivera', 15, '1070 Paw Ave, Minnesota, MN 55790', '2201'),('220002', 'John Evans', 14, '1070 Paw Ave, Minnesota, MN 55790', '2201'),('220003', 'Riley Miller', 71, '1070 Paw Ave, Minnesota, MN 55790', '2201'),
('220004', 'Benjamin Davis', 20, '1070 Paw Ave, Minnesota, MN 55790', '2201'),('220005', 'Madison Baker', 35, '1070 Paw Ave, Minnesota, MN 55790', '2201'),('230001', 'Charlotte Young', 37, '1071 Shelter Rd, Mississippi, MS 24246', '2301'),('230002', 'Ethan Harris', 78, '1071 Shelter Rd, Mississippi, MS 24246', '2301'),
('230003', 'Nora Moore', 27, '1071 Shelter Rd, Mississippi, MS 24246', '2301'),('230004', 'John White', 44, '1071 Shelter Rd, Mississippi, MS 24246', '2301'),('230005', 'Avery Reyes', 27, '1071 Shelter Rd, Mississippi, MS 24246', '2301'),('240001', 'Luna Martinez', 88, '1072 Compassion Way, Missouri, MO 85886', '2401'),
('240002', 'Wyatt Gonzalez', 82, '1072 Compassion Way, Missouri, MO 85886', '2401'),('240003', 'Elijah Cooper', 34, '1072 Compassion Way, Missouri, MO 85886', '2401'),('240004', 'Olivia Lopez', 65, '1072 Compassion Way, Missouri, MO 85886', '2401'),('240005', 'Logan Perez', 63, '1072 Compassion Way, Missouri, MO 85886', '2401'),
('250001', 'David Morales', 33, '1073 Harmony St, Montana, MT 82346', '2501'),('250002', 'Zoey Ramirez', 7, '1073 Harmony St, Montana, MT 82346', '2501'),('250003', 'Madison Davis', 12, '1073 Harmony St, Montana, MT 82346', '2501'),('250004', 'Abigail Carter', 82, '1073 Harmony St, Montana, MT 82346', '2501'),
('250005', 'Liam Roberts', 55, '1073 Harmony St, Montana, MT 82346', '2501'),('260001', 'Sofia Collins', 36, '1074 Shelter Rd, Nebraska, NE 77561', '2601'),('260002', 'Jack Diaz', 6, '1074 Shelter Rd, Nebraska, NE 77561', '2601'),('260003', 'Luke Martin', 1, '1074 Shelter Rd, Nebraska, NE 77561', '2601'),
('260004', 'Ethan Nguyen', 43, '1074 Shelter Rd, Nebraska, NE 77561', '2601'),('260005', 'Elizabeth Davis', 17, '1074 Shelter Rd, Nebraska, NE 77561', '2601'),('270001', 'Sophia Green', 82, '1075 Paw Ave, Nevada, NV 40091', '2701'),('270002', 'Sophia Miller', 34, '1075 Paw Ave, Nevada, NV 40091', '2701'),
('270003', 'Zoey Cook', 21, '1075 Paw Ave, Nevada, NV 40091', '2701'),('270004', 'Mason Davis', 57, '1075 Paw Ave, Nevada, NV 40091', '2701'),('270005', 'James White', 71, '1075 Paw Ave, Nevada, NV 40091', '2701'),('280001', 'William Rodriguez', 55, '1076 Harmony St, New Hampshire, NH 53101', '2801'),
('280002', 'Logan Phillips', 72, '1076 Harmony St, New Hampshire, NH 53101', '2801'),('280003', 'Amelia Young', 2, '1076 Harmony St, New Hampshire, NH 53101', '2801'),('280004', 'Ava Hernandez', 15, '1076 Harmony St, New Hampshire, NH 53101', '2801'),('280005', 'Ellie Gutierrez', 10, '1076 Harmony St, New Hampshire, NH 53101', '2801'),
('290001', 'Owen King', 89, '1077 Rescue Blvd, New Jersey, NJ 93590', '2901'),('290002', 'Daniel Green', 20, '1077 Rescue Blvd, New Jersey, NJ 93590', '2901'),('290003', 'Logan King', 70, '1077 Rescue Blvd, New Jersey, NJ 93590', '2901'),('290004', 'Mateo Taylor', 5, '1077 Rescue Blvd, New Jersey, NJ 93590', '2901'),
('290005', 'Aiden Collins', 48, '1077 Rescue Blvd, New Jersey, NJ 93590', '2901'),('300001', 'Owen Martinez', 75, '1078 Shelter Rd, New Mexico, NM 88042', '3001'),('300002', 'Olivia Collins', 71, '1078 Shelter Rd, New Mexico, NM 88042', '3001'),('300003', 'Benjamin Martinez', 19, '1078 Shelter Rd, New Mexico, NM 88042', '3001'),
('300004', 'Elizabeth Cook', 56, '1078 Shelter Rd, New Mexico, NM 88042', '3001'),('300005', 'Sofia Taylor', 17, '1078 Shelter Rd, New Mexico, NM 88042', '3001'),('310001', 'Sophia Smith', 13, '1079 Harmony St, New York, NY 97806', '3101'),('310002', 'Evelyn Davis', 46, '1079 Harmony St, New York, NY 97806', '3101'),
('310003', 'Mason Jones', 45, '1079 Harmony St, New York, NY 97806', '3101'),('310004', 'Elijah Perez', 78, '1080 Rescue Blvd, New York, NY 30866', '3102'),('310005', 'Sebastian Williams', 34, '1080 Rescue Blvd, New York, NY 30866', '3102'),('310006', 'Nova Wilson', 6,  '1080 Rescue Blvd, New York, NY 30866', '3102'),
('310007', 'Noah Smith', 59, '1081 Harmony St, New York, NY 15075', '3103'),('310008', 'Ava Miller', 69, '1081 Harmony St, New York, NY 15075', '3103'),('310009', 'Mason Taylor', 16, '1081 Harmony St, New York, NY 15075', '3103'),('320001', 'Owen Smith', 49, '1082 Paw Ave, North Carolina, NC 39219', '3201'),
('320002', 'Chloe Miller', 11, '1082 Paw Ave, North Carolina, NC 39219', '3201'),('320003', 'Sebastian Wilson', 71, '1082 Paw Ave, North Carolina, NC 39219', '3201'),('320004', 'Mason Anderson', 38, '1083 Paw Ave, North Carolina, NC 70332', '3202'),('320005', 'Nova Rodriguez', 81, '1083 Paw Ave, North Carolina, NC 70332', '3202'),
('320006', 'Liam Harris', 80, '1083 Paw Ave, North Carolina, NC 70332', '3202'),('330001', 'Benjamin Thompson', 47, '1084 Rescue Blvd, North Dakota, ND 56025', '3301'),('330002', 'Madison Hernandez', 74, '1084 Rescue Blvd, North Dakota, ND 56025', '3301'),('330003', 'Evelyn Jones', 25, '1084 Rescue Blvd, North Dakota, ND 56025', '3301'),
('330004', 'Amelia Harris', 9, '1085 Compassion Way, North Dakota, ND 56025', '3302'),('330005', 'Abigail Brown', 6, '1085 Compassion Way, North Dakota, ND 56025', '3302'),('330006', 'Ava Gonzalez', 85, '1085 Compassion Way, North Dakota, ND 56025', '3302'),('340001', 'Mason Smith', 21, '1086 Compassion Way, Ohio, OH 44795', '3401'),
('340002', 'Chloe Davis', 59, '1086 Compassion Way, Ohio, OH 44795', '3401'),('340003', 'Daniel Jones', 1, '1086 Compassion Way, Ohio, OH 44795', '3401'),('340004', 'Amelia Perez', 34, '1086 Compassion Way, Ohio, OH 44795', '3401'),('340005', 'Christian Williams', 65, '1086 Compassion Way, Ohio, OH 44795', '3401'),
('350001', 'Zoey Johnson', 23, '1087 Compassion Way, Oklahoma, OK 66959', '3501'),('350002', 'Emma Williams', 65, '1087 Compassion Way, Oklahoma, OK 66959', '3501'),('350003', 'Madison Davis', 14, '1087 Compassion Way, Oklahoma, OK 66959', '3501'),('350004', 'Brooklyn Martin', 81, '1088 Harmony St, Oklahoma, OK 89457', '3502'),
('350005', 'Emma Moore', 39, '1088 Harmony St, Oklahoma, OK 89457', '3502'),('350006', 'Ella Thompson', 82, '1088 Harmony St, Oklahoma, OK 89457', '3502'),('360001', 'Christian Wilson', 65, '1089 Harmony St, Oregon, OR 85574', '3601'),('360002', 'Daniel Anderson', 78, '1089 Harmony St, Oregon, OR 85574', '3601'),
('360003', 'Chloe Sanchez', 26, '1089 Harmony St, Oregon, OR 85574', '3601'),('360004', 'Liam Harris', 20, '1089 Harmony St, Oregon, OR 85574', '3601'),('360005', 'Ava Brooks', 90, '1089 Harmony St, Oregon, OR 85574', '3601'),('370001', 'Sebastian Campbell', 41, '1090 Shelter Rd, Pennsylvania, PA 67154', '3701'),
('370002', 'Madison Clark', 38, '1090 Shelter Rd, Pennsylvania, PA 67154', '3701'),('370003', 'Chloe Thompson', 27, '1090 Shelter Rd, Pennsylvania, PA 67154', '3701'),('370004', 'Noah Rodriguez', 7, '1090 Shelter Rd, Pennsylvania, PA 67154', '3701'),('370005', 'Liam Martinez', 90, '1090 Shelter Rd, Pennsylvania, PA 67154', '3701'),
('380001', 'Oliver Lopez', 82, '1091 Harmony St, Rhode Island, RI 43210', '3801'),('380002', 'Isabella White', 57, '1091 Harmony St, Rhode Island, RI 43210', '3801'),('380003', 'Ethan Wright', 15, '1091 Harmony St, Rhode Island, RI 43210', '3801'),('380004', 'Charlotte Adams', 45, '1091 Harmony St, Rhode Island, RI 43210', '3801'),
('380005', 'Benjamin Davis', 23, '1091 Harmony St, Rhode Island, RI 43210', '3801'),('390001', 'Michael Perez', 30, '1092 Rescue Blvd, South Carolina, SC 15983', '3901'),('390002', 'Emily Turner', 46, '1092 Rescue Blvd, South Carolina, SC 15983', '3901'),('390003', 'James Reed', 51, '1092 Rescue Blvd, South Carolina, SC 15983', '3901'),
('390004', 'Ava Gonzalez', 36, '1092 Rescue Blvd, South Carolina, SC 15983', '3901'),('390005', 'Joseph Carter', 75, '1092 Rescue Blvd, South Carolina, SC 15983', '3901'),('400001', 'Lily Morgan', 28, '1093 Rescue Blvd, South Dakota, SD 84736', '4001'),('400002', 'Owen Cooper', 55, '1093 Rescue Blvd, South Dakota, SD 84736', '4001'),
('400003', 'Chloe Torres', 67, '1093 Rescue Blvd, South Dakota, SD 84736', '4001'),('400004', 'Matthew Hill', 49, '1093 Rescue Blvd, South Dakota, SD 84736', '4001'),('400005', 'Evelyn Nelson', 9, '1093 Rescue Blvd, South Dakota, SD 84736', '4001'),('410001', 'Noah Sanchez', 1, '1094 Harmony St, Tennessee, TN 54781', '4101'),
('410002', 'Mia Lopez', 81, '1094 Harmony St, Tennessee, TN 54781', '4101'),('410003', 'Liam Nguyen', 8, '1094 Harmony St, Tennessee, TN 54781', '4101'),('410004', 'Emma Green', 32, '1094 Harmony St, Tennessee, TN 54781', '4101'),('410005', 'Oliver Adams', 72, '1094 Harmony St, Tennessee, TN 54781', '4101'),
('430001', 'James Perez', 71, '1095 Paw Ave, Texas, TX 31620', '4301'),('430002', 'Charlotte Gomez', 24, '1095 Paw Ave, Texas, TX 31620', '4301'),('430003', 'Henry Jackson', 34, '1095 Paw Ave, Texas, TX 31620', '4301'),('430004', 'Luna Stewart', 5, '1096 Shelter Rd, Texas, TX 18592', '4302'),
('430005', 'Amelia King', 91, '1096 Shelter Rd, Texas, TX 18592', '4302'),('430006', 'Aiden Torres', 64, '1096 Shelter Rd, Texas, TX 18592', '4302'),('430007', 'Layla Wright', 22, '1097 Compassion Way, Texas, TX 43958', '4303'),('430008', 'William Powell', 88, '1097 Compassion Way, Texas, TX 43958', '4303'),
('430009', 'Mason Russell', 30, '1097 Compassion Way, Texas, TX 43958', '4303'),('430010', 'Evelyn Allen', 57, '1098 Harmony St, Texas, TX 78904', '4304'),('430011', 'Michael Bennett', 61, '1098 Harmony St, Texas, TX 78904', '4304'),('430012', 'Elizabeth Carter', 15, '1098 Harmony St, Texas, TX 78904', '4304'),
('440001', 'Owen Rivera', 74, '1099 Paw Ave, Utah, UT 96842', '4401'),('440002', 'Ella Collins', 39, '1099 Paw Ave, Utah, UT 96842', '4401'),('440003', 'Leo Edwards', 88, '1099 Paw Ave, Utah, UT 96842', '4401'),('440004', 'Avery Morris', 23, '1099 Paw Ave, Utah, UT 96842', '4401'),
('440005', 'Sophia Rodriguez', 55, '1099 Paw Ave, Utah, UT 96842', '4401'),('450001', 'Harper King', 76, '1100 Shelter Rd, Vermont, VT 23645', '4501'),('450002', 'Jack Morris', 58, '1100 Shelter Rd, Vermont, VT 23645', '4501'),('450003', 'Joseph Lopez', 29, '1100 Shelter Rd, Vermont, VT 23645', '4501'),
('450004', 'Isaac Thomas', 9, '1101 Shelter Rd, Vermont, VT 65162', '4502'),('450005', 'Mia Harris', 44, '1101 Shelter Rd, Vermont, VT 65162', '4502'),('450006', 'Elijah Ramirez', 3, '1101 Shelter Rd, Vermont, VT 65162', '4502'),('460001', 'Mason Jones', 76, '1102 Harmony St, Virginia, VA 29031', '4601'),
('460002', 'William Sanchez', 71, '1102 Harmony St, Virginia, VA 29031', '4601'),('460003', 'James Gonzalez', 30, '1102 Harmony St, Virginia, VA 29031', '4601'),('460004', 'Camila Martin', 76, '1103 Paw Ave, Virginia, VA 41579', '4602'),('460005', 'Carter Taylor', 29, '1103 Paw Ave, Virginia, VA 41579', '4602'),
('460006', 'Jackson Moore', 1, '1103 Paw Ave, Virginia, VA 41579', '4602'),('470001', 'Olivia Perez', 10, '1104 Shelter Rd, Washington, WA 68319', '4701'),('470002', 'Mason Perez', 81, '1104 Shelter Rd, Washington, WA 68319', '4701'),('470003', 'Violet Harris', 8, '1104 Shelter Rd, Washington, WA 68319', '4701'),
('470004', 'Sebastian Harris', 30, '1104 Shelter Rd, Washington, WA 68319', '4701'),('470005', 'Nova Wilson', 9, '1104 Shelter Rd, Washington, WA 68319', '4701'),('470201', 'Liam Smith', 34, '1105 Rescue Blvd, Washington, WA 25063', '4702'),('470202', 'Olivia Johnson', 27, '1105 Rescue Blvd, Washington, WA 25063', '4702'),
('470203', 'Noah Brown', 45, '1105 Rescue Blvd, Washington, WA 25063', '4702'),('470204', 'Emma Jones', 52, '1105 Rescue Blvd, Washington, WA 25063', '4702'),('470205', 'Oliver Garcia', 19, '1105 Rescue Blvd, Washington, WA 25063', '4702'),('480101', 'Ava Miller', 61, '1106 Rescue Blvd, West Virginia, WV 56920', '4801'),
('480102', 'Elijah Davis', 23, '1106 Rescue Blvd, West Virginia, WV 56920', '4801'),('480103', 'Sophia Rodriguez', 38, '1106 Rescue Blvd, West Virginia, WV 56920', '4801'),('480104', 'James Martinez', 71, '1106 Rescue Blvd, West Virginia, WV 56920', '4801'),('480105', 'Isabella Anderson', 9, '1106 Rescue Blvd, West Virginia, WV 56920', '4801'),
('490101', 'Benjamin Thomas', 56, '1107 Paw Ave, Wisconsin, WI 30479', '4901'),('490102', 'Mia Taylor', 14, '1107 Paw Ave, Wisconsin, WI 30479', '4901'),('490103', 'Lucas Moore', 82, '1107 Paw Ave, Wisconsin, WI 30479', '4901'),('490104', 'Amelia Jackson', 5, '1107 Paw Ave, Wisconsin, WI 30479', '4901'),
('490105', 'Mason Martin', 29, '1107 Paw Ave, Wisconsin, WI 30479', '4901'),('500101', 'Harper Lee', 47, '1108 Compassion Way, Wyoming, WY 18647', '5001'),('500102', 'Logan Perez', 33, '1108 Compassion Way, Wyoming, WY 18647', '5001'),('500103', 'Evelyn White', 60, '1108 Compassion Way, Wyoming, WY 18647', '5001'),('500104', 'Alexander Harris', 8, '1108 Compassion Way, Wyoming, WY 18647', '5001'),('500105', 'Charlotte Sanchez', 73, '1108 Compassion Way, Wyoming, WY 18647', '5001');

INSERT INTO Disaster
  (Disaster_ID, Disaster_Name, Location, Severity, Start_Date,   End_Date)VALUES
('WF001', 'Alabama Wildfire 2024','Alabama',69142, '2024-07-12', '2024-09-05'),('WF002', 'Alaska Wildfire 2024','Alaska',24603, '2024-10-25', '2024-10-31'),
('WF003', 'Arizona Wildfire 2024','Arizona',38659, '2024-07-29', '2024-07-30'),('WF004', 'Arkansas Wildfire 2024','Arkansas',97136, '2024-03-23', '2024-04-16'),
('WF005', 'California Wildfire 2024','California',62334, '2024-09-18', '2024-10-25'),('WF006', 'Colorado Wildfire 2024','Colorado',77880, '2024-12-27', '2024-12-31'),
('WF007', 'Connecticut Wildfire 2024','Connecticut',43585, '2024-11-26', '2024-12-07'),('WF008', 'Delaware Wildfire 2024','Delaware',52820, '2024-11-28', '2024-12-26'),
('WF009', 'Florida Wildfire 2024','Florida',82023, '2024-09-17', '2024-11-09'),('WF010', 'Georgia Wildfire 2024','Georgia',938, '2024-05-03', '2024-06-12'),
('WF011', 'Hawaii Wildfire 2024','Hawaii',28352, '2024-10-24', '2024-11-24'),('WF012', 'Idaho Wildfire 2024','Idaho',45801, '2024-11-11', '2024-11-27'),
('WF013', 'Illinois Wildfire 2024','Illinois',99549, '2024-12-26', '2024-12-29'),('WF014', 'Indiana Wildfire 2024','Indiana',19426, '2024-10-03', '2024-11-19'),
('WF015', 'Iowa Wildfire 2024','Iowa',49054, '2024-09-15', '2024-10-12'),('WF016', 'Kansas Wildfire 2024','Kansas',71495, '2024-11-02', '2024-11-06'),
('WF017', 'Kentucky Wildfire 2024','Kentucky',4331, '2024-08-26', '2024-10-12'),('WF018', 'Louisiana Wildfire 2024','Louisiana',48560, '2024-04-17', '2024-05-14'),
('WF019', 'Maine Wildfire 2024','Maine',87810, '2024-05-23', '2024-06-10'),('WF020', 'Maryland Wildfire 2024','Maryland',37516, '2024-01-06', '2024-01-19'),
('WF021', 'Massachusetts Wildfire 2024','Massachusetts',36496, '2024-02-10', '2024-04-01'),('WF022', 'Michigan Wildfire 2024','Michigan',99698, '2024-10-22', '2024-11-18'),
('WF023', 'Minnesota Wildfire 2024','Minnesota',29297, '2024-10-30', '2024-12-25'),('WF024', 'Mississippi Wildfire 2024','Mississippi',81696, '2024-04-20', '2024-04-22'),
('WF025', 'Missouri Wildfire 2024','Missouri',86857, '2024-11-20', '2024-12-11'),('WF026', 'Montana Wildfire 2024','Montana', 20649, '2024-12-08', '2024-12-30'),
('WF027', 'Nebraska Wildfire 2024','Nebraska',38833, '2024-09-14', '2024-11-09'),('WF028', 'Nevada Wildfire 2024','Nevada',21873, '2024-01-31', '2024-03-27'),
('WF029', 'New Hampshire Wildfire 2024', 'New Hampshire',90809, '2024-02-25', '2024-03-16'),('WF030', 'New Jersey Wildfire 2024', 'New Jersey', 99423, '2024-05-28', '2024-05-31'),
('WF031', 'New Mexico Wildfire 2024', 'New Mexico', 70697, '2024-01-27', '2024-03-13'),('WF032', 'New York Wildfire 2024','New York',89927, '2024-08-11', '2024-09-03'),
('WF033', 'North Carolina Wildfire 2024', 'North Carolina', 45766, '2024-02-20', '2024-03-07'),('WF034', 'North Dakota Wildfire 2024','North Dakota',   45674, '2024-07-27', '2024-08-05'),
('WF035', 'Ohio Wildfire 2024','Ohio',43982, '2024-05-17', '2024-06-01'),('WF036', 'Oklahoma Wildfire 2024','Oklahoma',64822, '2024-12-25', '2024-12-26'),
('WF037', 'Oregon Wildfire 2024', 'Oregon',97512, '2024-04-02', '2024-04-26'),('WF038', 'Pennsylvania Wildfire 2024', 'Pennsylvania', 44983, '2024-01-25', '2024-02-24'),
('WF039', 'Rhode Island Wildfire 2024', 'Rhode Island', 49928, '2024-11-29', '2024-12-26'),('WF040', 'South Carolina Wildfire 2024', 'South Carolina', 71703, '2024-02-13', '2024-03-26'),
('WF041', 'South Dakota Wildfire 2024', 'South Dakota', 30326, '2024-11-23', '2024-12-24'),('WF042', 'Tennessee Wildfire 2024', 'Tennessee', 68905, '2024-12-04', '2024-12-17'),
('WF043', 'Texas Wildfire 2024', 'Texas', 26713, '2024-10-08', '2024-11-30'),('WF044', 'Utah Wildfire 2024', 'Utah', 55491, '2024-11-26', '2024-12-22'),('WF045', 'Vermont Wildfire 2024', 'Vermont', 71295, '2024-05-11', '2024-06-29'),
('WF046', 'Virginia Wildfire 2024', 'Virginia', 5681, '2024-06-16', '2024-07-21'),('WF047', 'Washington Wildfire 2024', 'Washington',18613, '2024-05-26', '2024-06-11'),
('WF048', 'West Virginia Wildfire 2024', 'West Virginia',  40631, '2024-07-14', '2024-09-04'),('WF049', 'Wisconsin Wildfire 2024', 'Wisconsin',55168, '2024-12-30', '2024-12-31'),('WF050', 'Wyoming Wildfire 2024', 'Wyoming', 38554, '2024-09-07', '2024-10-26');

INSERT INTO Victim_Assistance_Needed (Victim_ID, Assistance_Needed) VALUES
('010001','Yes'),('010002','Yes'),('010003','No'),('020001','Yes'),('020002','Yes'),('020003','Yes'),('020004','Yes'),('020005','Yes'),('020006','Yes'),
('030002','No'),('030003','Yes'),('030004','No'),('030005','Yes'),('030006','Yes'),('040001','Yes'),('040002','Yes'),('040003','No'),('040004','Yes'),('040005','Yes'),
('050001','Yes'),('050002','Yes'),('050003','Yes'),('050004','Yes'),('050005','Yes'),('050006','No'),('050007','Yes'),('050008','Yes'),('050009','Yes'),('050010','Yes'),('050011','Yes'),('050012','No'),
('050013','Yes'),('050014','Yes'),('050015','Yes'),('050016','Yes'),('050017','No'),('050018','Yes'),('050019','Yes'),('050020','Yes'),('050021','Yes'),('050022','Yes'),('050023','No'),('050024','Yes'),
('050025','Yes'),('050026','Yes'),('050027','Yes'),('050028','No'),('050029','Yes'),('050030','Yes'),('060001','No'),('060002','Yes'),('060352','Yes'),('069459','No'),('066227','Yes'),('064741','Yes'),
('066201','Yes'),('063432','Yes'),('064010','No'),('064554','Yes'),('061307','Yes'),('061139','Yes'),('065820','Yes'),('068751','No'),('063733','Yes'),('061169','Yes'),('060750','Yes'),('065925','Yes'),
('061654','Yes'),('065977','Yes'),('062664','No'),('066065','Yes'),('063814','Yes'),('063150','No'),('062045','Yes'),('069044','Yes'),('067428','Yes'),('061291','Yes'),('071674','No'),('075514','Yes'),
('074552','Yes'),('071519','Yes'),('070711','Yes'),('073527','No'),('071584','Yes'),('075635','Yes'),('076224','Yes'),('077527','Yes'),('079891','No'),('072547','Yes'),('074333','Yes'),('075881','No'),
('075574','Yes'),('081535','Yes'),('086912','Yes'),('080520','Yes'),('083582','No'),('080488','Yes'),('099891','Yes'),('096201','Yes'),('095881','No'),('092045','Yes'),('091584','Yes'),('091674','Yes'),
('097527','Yes'),('094333','No'),('099459','Yes'),('091519','Yes'),('095635','Yes'),('094741','Yes'),('094803','No'),('091139','Yes'),('090711','Yes'),('093814','Yes'),('099044','No'),('093150','Yes'),
('096224','Yes'),('098785','Yes'),('095925','Yes'),('093733','No'),('090750','Yes'),('091291','Yes'),('091307','Yes'),('100054','Yes'),('100055','No'),('090001','Yes'),('090002','Yes'),('090003','Yes'),
('090004','Yes'),('090005','No'),('090006','Yes'),('100001','Yes'),('100002','Yes'),('100003','Yes'),('100004','No'),('100005','Yes'),('110625','Yes'),('118785','Yes'),('114367','Yes'),('116211','No'),  ('111764','Yes'),('120845','Yes'),('121379','Yes'),('122014','Yes'),('128501','No'),('125763','Yes'),
('120992','Yes'),('130488','Yes'),  ('137359','Yes'),('139863','Yes'),('138928','No'),('138279','Yes'),('133811','Yes'),  ('130520','Yes'),('133611','No'),('133582','Yes'),('139654','Yes'),('133257','Yes'),
('131535','No'),('139195','Yes'),('130434','Yes'),('136873','Yes'),('140027','No'),('142615','Yes'),('145524','Yes'),('151144','Yes'),('151435','No'),('154016','Yes'),
('164133','Yes'),('167564','Yes'),('162223','Yes'),('165733','No'),('167449','Yes'),  ('164558','Yes'),('163467','Yes'),('160853','Yes'),('165355','Yes'),('167705','No'),
('167022','Yes'),('163673','Yes'),('161341','Yes'),('165529','No'),('160823','Yes'),('161124','Yes'),('166211','Yes'),('164262','Yes'),('166906','Yes'),('160317','No'),
('162977','Yes'),('161375','Yes'),('165363','Yes'),('168837','Yes'),('175313','No'),  ('173814','Yes'),('174374','Yes'),('171796','Yes'),('179197','Yes'),('172621','No'),  ('172677','Yes'),('173456','Yes'),('172266','Yes'),('173752','Yes'),('174741','Yes'),
('176227','Yes'),('175168','Yes'),('176304','No'),('178751','Yes'),('174889','Yes'),('171743','Yes'),('178317','No'),('183258','Yes'),('186126','Yes'),('188837','Yes'),('180009','No'),('185310','Yes'),('180319','Yes'),  ('185947','Yes'),('183923','No'),('183946','Yes'),('181290','Yes'),('187962','Yes'),
('188727','Yes'),('190001','Yes'),('190002','Yes'),('190003','Yes'),('190004','Yes'),  ('190005','Yes'),('200001','No'),('200002','Yes'),('200003','Yes'),('200004','Yes'),
('200005','No'),('210001','Yes'),('210002','Yes'),('210003','No'),('210004','Yes'),  ('210005','Yes'),('220001','Yes'),('220002','No'),('220003','Yes'),('220004','Yes'),
('220005','Yes'),('230001','Yes'),('230002','Yes'),('230003','No'),('230004','Yes'),('230005','Yes'), ('240001','Yes'),('240002','Yes'),('240003','No'),('240004','No'),('240005','No'),
('250001','Yes'),('250002','Yes'),('250003','Yes'),('250004','Yes'),('250005','Yes'),  ('260001','No'),('260002','No'),('260003','Yes'),('260004','No'),('260005','Yes'),  ('270001','Yes'),('270002','Yes'),('270003','Yes'),('270004','Yes'),('270005','Yes'),  ('280001','Yes'),('280002','Yes'),('280003','Yes'),('280004','Yes'),('280005','Yes'),
('290001','Yes'),('290002','Yes'),('290003','Yes'),('290004','Yes'),('290005','Yes'), ('300001','Yes'),('300002','Yes'),('300003','Yes'),('300004','Yes'),
('310005','Yes'),('310006','Yes'),('310007','No'),('310008','Yes'),('310009','Yes'),('320001','No'),('320002','Yes'),('320003','Yes'),('320004','Yes'),('320005','No'),('320006','Yes'),
('330001','Yes'),('330002','Yes'),('330003','Yes'),('330004','Yes'),('330005','No'),('330006','Yes'),('340001','Yes'),('340002','Yes'), ('340003','Yes'),('340004','Yes'),('340005','Yes'),
('350001','Yes'),('350002','No'), ('350003','Yes'),('350004','Yes'),('350005','No'),('350006','No'),('360001','Yes'),('360002','Yes'),('360003','Yes'),('360004','Yes'),('360005','Yes'),
('370001','Yes'),('370002','Yes'),('370003','No'), ('370004','Yes'),('370005','Yes'),('380001','Yes'),('380002','Yes'),('380003','Yes'),('380004','Yes'),('380005','Yes'),
('390001','Yes'),('390002','Yes'),('390003','Yes'),('390004','Yes'),('390005','No'),  ('400001','Yes'),('400002','No'), ('400003','No'), ('400004','Yes'),('400005','Yes'),
('410001','Yes'),('410002','Yes'),('410003','No'), ('410004','Yes'),('410005','Yes'),('430001','Yes'),('430002','Yes'),('430003','Yes'),('450006','Yes'),('460001','No'),('460002','Yes'),('460003','Yes'),('460004','Yes'),
('460005','Yes'),('460006','No'),('470001','Yes'),('470002','Yes'),('470003','No'),('470004','Yes'),('470005','Yes'),('470021','Yes'),('470022','No'),('470023','Yes'),
('470024','Yes'),('470025','Yes'),('480101','No'),('480102','Yes'),('480103','Yes'),('480104','Yes'),('480105','Yes'),('490101','Yes'),('490102','Yes'),('490103','Yes'),
('490104','Yes'),('490105','Yes'),('500101','Yes'),('500102','Yes'),('500103','Yes'),('500104','No'),('500105','Yes');

INSERT INTO Volunteer (Volunteer_ID, Volunteer_Name, Phone, Availability) VALUES
('VOL001','Alice Anderson','(512) 555-1001','Mon–Fri'), ('VOL002','Bob Anderson','(512) 555-1002','Mon–Fri'),('VOL003','Carol Anderson','(512) 555-1003','Mon–Fri'),('VOL004','Dave Anderson','(512) 555-1004','Mon–Fri'),
('VOL005','Eve Anderson','(512) 555-1005','Mon–Fri'),('VOL006','Frank Anderson','(512) 555-1006','Mon–Fri'),('VOL007','Grace Anderson','(512) 555-1007','Mon–Fri'), ('VOL008','Heidi Anderson','(512) 555-1008','Mon–Fri'),
('VOL009','Ivan Anderson','(512) 555-1009','Mon–Fri'),('VOL010','Judy Anderson','(512) 555-1010','Mon–Fri'),('VOL011','Alice Brown','(512) 555-1011','Mon–Fri'),('VOL012','Bob Brown','(512) 555-1012','Mon–Fri'),
('VOL013','Carol Brown','(512) 555-1013','Mon–Fri'),('VOL014','Dave Brown','(512) 555-1014','Mon–Fri'),('VOL015','Eve Brown','(512) 555-1015','Mon–Fri'),('VOL016','Frank Brown','(512) 555-1016','Mon–Fri'),
('VOL017','Grace Brown','(512) 555-1017','Mon–Fri'),('VOL018','Heidi Brown','(512) 555-1018','Mon–Fri'),('VOL019','Ivan Brown','(512) 555-1019','Mon–Fri'),('VOL020','Judy Brown','(512) 555-1020','Mon–Fri'),
('VOL021','Alice Clark','(512) 555-1021','Mon–Fri'),('VOL022','Bob Clark','(512) 555-1022','Mon–Fri'),('VOL023','Carol Clark','(512) 555-1023','Mon–Fri'),('VOL024','Dave Clark','(512) 555-1024','Mon–Fri'),
('VOL025','Eve Clark','(512) 555-1025','Mon–Fri'),('VOL026','Frank Clark','(512) 555-1026','Mon–Fri'),('VOL027','Grace Clark','(512) 555-1027','Mon–Fri'),('VOL028','Heidi Clark','(512) 555-1028','Mon–Fri'),
('VOL029','Ivan Clark','(512) 555-1029','Mon–Fri'),('VOL030','Judy Clark','(512) 555-1030','Mon–Fri'),('VOL031','Alice Davis','(512) 555-1031','Mon–Fri'),('VOL032','Bob Davis','(512) 555-1032','Mon–Fri'),('VOL033','Carol Davis','(512) 555-1033','Mon–Fri'),
('VOL034','Dave Davis','(512) 555-1034','Mon–Fri'),('VOL035','Eve Davis','(512) 555-1035','Mon–Fri'),('VOL036','Frank Davis','(512) 555-1036','Mon–Fri'),('VOL037','Grace Davis','(512) 555-1037','Mon–Fri'),
('VOL038','Heidi Davis','(512) 555-1038','Mon–Fri'),('VOL039','Ivan Davis','(512) 555-1039','Mon–Fri'),('VOL040','Judy Davis','(512) 555-1040','Mon–Fri'),('VOL041','Alice Evans','(512) 555-1041','Mon–Fri'),
('VOL042','Bob Evans','(512) 555-1042','Mon–Fri'),('VOL043','Carol Evans','(512) 555-1043','Mon–Fri'),('VOL044','Dave Evans','(512) 555-1044','Mon–Fri'),
('VOL045','Eve Evans','(512) 555-1045','Mon–Fri'),('VOL046','Frank Evans','(512) 555-1046','Mon–Fri'),('VOL047','Grace Evans','(512) 555-1047','Mon–Fri'),('VOL048','Heidi Evans','(512) 555-1048','Mon–Fri'),
('VOL049','Ivan Evans','(512) 555-1049','Mon–Fri'),('VOL050','Judy Evans','(512) 555-1050','Mon–Fri'),('VOL051','Alice Franklin','(512) 555-1051','Mon–Fri'),('VOL052','Bob Franklin','(512) 555-1052','Mon–Fri'),
('VOL053','Carol Franklin','(512) 555-1053','Mon–Fri'),('VOL054','Dave Franklin','(512) 555-1054','Mon–Fri'),('VOL055','Eve Franklin','(512) 555-1055','Mon–Fri'),('VOL056','Frank Franklin','(512) 555-1056','Mon–Fri'),
('VOL057','Grace Franklin','(512) 555-1057','Mon–Fri'),('VOL058','Heidi Franklin','(512) 555-1058','Mon–Fri'),('VOL059','Ivan Franklin','(512) 555-1059','Mon–Fri'),('VOL060','Judy Franklin','(512) 555-1060','Mon–Fri'),
('VOL061','Alice Garcia','(512) 555-1061','Mon–Fri'),('VOL062','Bob Garcia','(512) 555-1062','Mon–Fri'),('VOL063','Carol Garcia','(512) 555-1063','Mon–Fri'),('VOL064','Dave Garcia','(512) 555-1064','Mon–Fri'),
('VOL065','Eve Garcia','(512) 555-1065','Mon–Fri'),('VOL066','Frank Garcia','(512) 555-1066','Mon–Fri'),('VOL067','Grace Garcia','(512) 555-1067','Mon–Fri'),('VOL068','Heidi Garcia','(512) 555-1068','Mon–Fri'),
('VOL069','Ivan Garcia','(512) 555-1069','Mon–Fri'),('VOL070','Judy Garcia','(512) 555-1070','Mon–Fri'),('VOL071','Alice Harris','(512) 555-1071','Mon–Fri'),('VOL072','Bob Harris','(512) 555-1072','Mon–Fri'),
('VOL073','Carol Harris','(512) 555-1073','Mon–Fri'),('VOL074','Dave Harris','(512) 555-1074','Mon–Fri'),('VOL075','Eve Harris','(512) 555-1075','Mon–Fri'),('VOL076','Frank Harris','(512) 555-1076','Mon–Fri'),
('VOL077','Grace Harris','(512) 555-1077','Mon–Fri'),('VOL078','Heidi Harris','(512) 555-1078','Mon–Fri'),('VOL079','Ivan Harris','(512) 555-1079','Mon–Fri'),('VOL080','Judy Harris','(512) 555-1080','Mon–Fri'),
('VOL081','Alice Ibrahim','(512) 555-1081','Mon–Fri'),('VOL082','Bob Ibrahim','(512) 555-1082','Mon–Fri'),('VOL083','Carol Ibrahim','(512) 555-1083','Mon–Fri'),('VOL084','Dave Ibrahim','(512) 555-1084','Mon–Fri'),
('VOL085','Eve Ibrahim','(512) 555-1085','Mon–Fri'),('VOL086','Frank Ibrahim','(512) 555-1086','Mon–Fri'),('VOL087','Grace Ibrahim','(512) 555-1087','Mon–Fri'),('VOL088','Heidi Ibrahim','(512) 555-1088','Mon–Fri'),
('VOL089','Ivan Ibrahim','(512) 555-1089','Mon–Fri'),('VOL090','Judy Ibrahim','(512) 555-1090','Mon–Fri'),('VOL091','Alice Jones','(512) 555-1091','Mon–Fri'),('VOL092','Bob Jones','(512) 555-1092','Mon–Fri'),
('VOL093','Carol Jones','(512) 555-1093','Mon–Fri'),('VOL094','Dave Jones','(512) 555-1094','Mon–Fri'),('VOL095','Eve Jones','(512) 555-1095','Mon–Fri'),('VOL096','Frank Jones','(512) 555-1096','Mon–Fri'),
('VOL097','Grace Jones','(512) 555-1097','Mon–Fri'),('VOL098','Heidi Jones','(512) 555-1098','Mon–Fri'),('VOL099','Ivan Jones','(512) 555-1099','Mon–Fri'),('VOL100','Judy Jones','(512) 555-1100','Mon–Fri');

INSERT INTO Donation (Donation_ID, Donor_Name, Date, Type, Amount) VALUES
  ('DON001','Acme Corp','2025-04-01','Water Bottles',2000),
  ('DON002','Beta LLC','2025-04-02','Canned Goods',2000),
  ('DON003','Gamma Inc','2025-04-03','Blanket',700),
  ('DON004','Delta Co','2025-04-04','Beds',500),
  ('DON005','Epsilon Ltd','2025-04-05','Pereshable Goods',2000),
  ('DON006','Zeta Group','2025-04-06','Toys',1000);

  
INSERT INTO Organization (Org_ID, Contact, Org_Name, Type) VALUES
  ('ORG001','info@redcross.org','American Red Cross','NGO'),
  ('ORG002','support@fedrelief.com','Federated Relief','Government'),
  ('ORG003','admin@worldfoodprog.org','World Food Programme','International'),
  ('ORG004','hq@unicef.org','UNICEF','International'),
  ('ORG005','contact@msf.org','Doctors Without Borders','NGO');

INSERT INTO Resource (Resource_ID, Resource_Name, Status,  Amount, Donation_ID, Org_ID) VALUES
  ('10023','Water Bottle','In Stock',2000,'DON001','ORG001'),
  ('12340','Canned Goods','In Stock',2500,'DON002','ORG002'),
  ('65234','Blanket','In Stock',1500,'DON003','ORG003'),
  ('83456','Beds','In Stock',500,'DON004','ORG004'),
  ('91234','Pereshable Goods','In Stock',2000,'DON005','ORG005'),
  ('70123','Toys','In Stock',1000,'DON006','ORG001');

  INSERT INTO Resource_Request (Resource_ID, Resource_Name, Request_ID, Amount, Status) VALUES
('10023','Water Bottle','20034',420,'In Progress'), ('10023','Water Bottle','21234',170,'In Progress'),   ('10023','Water Bottle','22345',29,'Completed'),('10023','Water Bottle','54321',8 ,'In Progress'), ('10023','Water Bottle','54320',50,'In Progress'),
('10023','Water Bottle','54319',23,'In Progress'), ('10023','Water Bottle','54318',46,'In Progress'), ('10023','Water Bottle','54317',5,'In Progress'), ('10023','Water Bottle','54316',37,'In Progress'), ('10023','Water Bottle','54315',12,'Completed'), ('10023','Water Bottle','54314',29,'In Progress'),
('10023','Water Bottle','54313',500,'Completed'), ('10023','Water Bottle','54312',50,'In Progress'), ('10023','Water Bottle','54311',3,'In Progress'),('10023','Water Bottle','54310',49,'In Progress'), ('10023','Water Bottle','54309',22,'In Progress'), ('10023','Water Bottle','54308',31,'Completed'),
('10023','Water Bottle','54307',80,'In Progress'), ('10023','Water Bottle','54306',27,'In Progress'), ('10023','Water Bottle','54305',45,'In Progress'),('10023','Water Bottle','54304',14,'In Progress'), ('10023','Water Bottle','54303',9,'In Progress'), ('10023','Water Bottle','54302',33,'In Progress'),
('10023','Water Bottle','54301',100,'In Progress'), ('10023','Water Bottle','54300',18,'Completed'), ('10023','Water Bottle','54299',39,'In Progress'),('12340','Canned Goods','54228',50,'In Progress'), ('12340','Canned Goods','54227',44,'Completed'), ('12340','Canned Goods','54226',17,'In Progress'), ('12340','Canned Goods','54225',29,'In Progress'),
('12340','Canned Goods','54224',50,'In Progress'), ('12340','Canned Goods','54223',12,'Completed'), ('12340','Canned Goods','54221',37,'In Progress'), ('12340','Canned Goods','54220',4,'In Progress'),
('12340','Canned Goods','54219',29,'In Progress'), ('12340','Canned Goods','54218',50,'In Progress'), ('12340','Canned Goods','54217',15,'Completed'),('12340','Canned Goods','54216',22,'In Progress'), ('12340','Canned Goods','54215',48,'In Progress'), ('12340','Canned Goods','54214',33,'In Progress'),('12340','Canned Goods','54213',7,'In Progress'),  ('12340','Canned Goods','54212',50,'Completed'), ('12340','Canned Goods','54211',23,'In Progress'),
('12340','Canned Goods','54210',80,'In Progress'),('12340','Canned Goods','54209',46,'In Progress'), ('12340','Canned Goods','54208',8,'Completed'),('12340','Canned Goods','54207',40,'In Progress'),('12340','Canned Goods','54206',28,'In Progress'), ('12340','Canned Goods','54205',19,'In Progress'),
('12340','Canned Goods','54204',29,'In Progress'), ('12340','Canned Goods','54203',35,'Completed'), ('12340','Canned Goods','54202',49,'In Progress'),('12340','Canned Goods','54201',17,'In Progress'),('12340','Canned Goods','54200',5,'In Progress'), ('12340','Canned Goods','54199',31,'In Progress'),
('12340','Canned Goods','54198',22,'Completed'), ('12340','Canned Goods','54197',46,'In Progress'), ('12340','Canned Goods','54196',9,'In Progress'),('12340','Canned Goods','54195',26,'In Progress'),('12340','Canned Goods','54194',14,'In Progress'), ('12340','Canned Goods','54193',39,'Completed'),
('12340','Canned Goods','54192',10,'In Progress'),('12340','Canned Goods','54191',180,'In Progress'), ('12340','Canned Goods','54190',47,'In Progress'),('12340','Canned Goods','54189',6,'In Progress'), ('12340','Canned Goods','54188',42,'Completed'), ('12340','Canned Goods','54187',25,'In Progress'),
('12340','Canned Goods','54186',32,'In Progress'),('12340','Canned Goods','54185',3,'In Progress'), ('12340','Canned Goods','54184',38,'In Progress'),('12340','Canned Goods','54183',16,'Completed'), ('12340','Canned Goods','54182',20,'In Progress'), ('12340','Canned Goods','54181',27,'In Progress'),
('12340','Canned Goods','54180',1,'In Progress'), ('12340','Canned Goods','54179',34,'In Progress'),  ('12340','Canned Goods','54178',41,'Completed'),('12340','Canned Goods','54177',13,'In Progress'),('12340','Canned Goods','54176',45,'In Progress'), ('12340','Canned Goods','54175',30,'In Progress'),
('12340','Canned Goods','54174',24,'In Progress'),('12340','Canned Goods','54173',36,'In Progress'), ('12340','Canned Goods','54172',21,'Completed'),('12340','Canned Goods','54171',44,'In Progress'),('12340','Canned Goods','54170',37,'In Progress'), ('12340','Canned Goods','54169',43,'In Progress'),
('12340','Canned Goods','54168',44,'Completed'), ('12340','Canned Goods','54167',2,'In Progress'), ('12340','Canned Goods','54166',12,'In Progress'),('12340','Canned Goods','54165',33,'In Progress'),('12340','Canned Goods','54164',26,'Completed'), ('65234','Blanket','54183','5','Completed'),
('65234','Blanket','54182',2,'In Progress'), ('65234','Blanket','54181',9,'In Progress'), ('65234','Blanket','54180',5,'In Progress'),('65234','Blanket','54179',17,'In Progress'), ('65234','Blanket','54178',3,'Completed'), ('65234','Blanket','54177',12,'In Progress'),
('65234','Blanket','54176',8,'In Progress'),  ('65234','Blanket','54175',9,'In Progress'), ('65234','Blanket','54174',5,'In Progress'),('65234','Blanket','54173',14,'In Progress'), ('65234','Blanket','54172',20,'Completed'), ('65234','Blanket','54171',11,'In Progress'),
('65234','Blanket','54170',7,'In Progress'),  ('65234','Blanket','54169',2,'In Progress'), ('65234','Blanket','54168',16,'Completed'),('65234','Blanket','54167',9,'In Progress'),  ('65234','Blanket','54166',10,'In Progress'), ('65234','Blanket','54165',13,'In Progress'),
('65234','Blanket','54164',4,'Completed'),    ('65234','Blanket','54163',8,'In Progress'), ('65234','Blanket','54162',6,'In Progress'),('65234','Blanket','54161',5,'In Progress'), ('65234','Blanket','54160',19,'Completed'), ('65234','Blanket','54159',1,'In Progress'),
('65234','Blanket','54158',7,'In Progress'), ('65234','Blanket','54157',8,'In Progress'), ('65234','Blanket','54156',12,'Completed'),('65234','Blanket','54155',3,'In Progress'),  ('65234','Blanket','54154',14,'In Progress'), ('65234','Blanket','54153',20,'In Progress'),
('65234','Blanket','54152',5,'In Progress'),  ('65234','Blanket','54151',9,'Completed'), ('65234','Blanket','54150',16,'In Progress'),('65234','Blanket','54149',2,'In Progress'),  ('65234','Blanket','54148',11,'In Progress'), ('65234','Blanket','54147',18,'In Progress'),
('65234','Blanket','54146',7,'In Progress'),  ('65234','Blanket','54145',1,'Completed'), ('65234','Blanket','54144',13,'In Progress'),('65234','Blanket','54143',4,'In Progress'),  ('65234','Blanket','54142',15,'In Progress'), ('65234','Blanket','54141',6,'Completed'),
('65234','Blanket','54140',10,'In Progress'), ('65234','Blanket','54139',9,'In Progress'), ('65234','Blanket','54138',7,'In Progress'),('65234','Blanket','54137',8,'In Progress'),  ('65234','Blanket','54136',12,'In Progress'), ('65234','Blanket','54135',14,'Completed'),
('65234','Blanket','54134',2,'In Progress'),  ('65234','Blanket','54133',1,'In Progress'), ('65234','Blanket','54132',6,'In Progress'),('65234','Blanket','54131',5,'In Progress'),  ('65234','Blanket','54130',9,'Completed'), ('65234','Blanket','54129',18,'In Progress'),
('65234','Blanket','54128',7,'In Progress'),  ('65234','Blanket','54127',2,'In Progress'), ('65234','Blanket','54126',1,'In Progress'),('65234','Blanket','54125',7,'Completed'),  ('65234','Blanket','54124',3,'In Progress'), ('65234','Blanket','54123',10,'In Progress'),
('65234','Blanket','54122',9,'In Progress'), ('65234','Blanket','54121',6,'In Progress'), ('65234','Blanket','54120',3,'In Progress'),('65234','Blanket','54119',8,'In Progress'),  ('65234','Blanket','54118',15,'In Progress'), ('65234','Blanket','54117',4,'Completed'),
('65234','Blanket','54116',12,'In Progress'), ('65234','Blanket','54115',17,'In Progress'), ('65234','Blanket','54114',2,'In Progress'),('65234','Blanket','54113',9,'Completed'),    ('65234','Blanket','54112',14,'In Progress'), ('65234','Blanket','54111',1,'In Progress'),
('65234','Blanket','54110',20,'In Progress'), ('65234','Blanket','54109',3,'Completed'), ('65234','Blanket','54108',11,'In Progress'),('65234','Blanket','54107',16,'In Progress'), ('65234','Blanket','54106',5,'In Progress'), ('65234','Blanket','54105',18,'Completed'),
('65234','Blanket','54104',7,'In Progress'),  ('65234','Blanket','54103',13,'In Progress'), ('65234','Blanket','54102',19,'In Progress'),('65234','Blanket','54101',2,'In Progress'),  ('65234','Blanket','54100',10,'In Progress'), ('65234','Blanket','54099',6,'In Progress'),
('65234','Blanket','54098',15,'In Progress'), ('65234','Blanket','54097',4,'In Progress'), ('65234','Blanket','54096',17,'In Progress'),('65234','Blanket','54095',8,'Completed'),    ('65234','Blanket','54094',12,'In Progress'), ('65234','Blanket','54093',20,'In Progress'),
('65234','Blanket','54092',3,'In Progress'),  ('65234','Blanket','54091',14,'Completed'), ('65234','Blanket','54090',9,'In Progress'),('65234','Blanket','54089',1,'In Progress'),  ('65234','Blanket','54088',11,'Completed'), ('65234','Blanket','54087',16,'In Progress'),
('65234','Blanket','54086',500,'In Progress'),  ('65234','Blanket','54085',18,'In Progress'),('83456','Beds','54084',2,'Completed'),('83456','Beds','54083',5,'In Progress'),  ('83456','Beds','54082',3,'In Progress'),
('83456','Beds','54081',4,'In Progress'),  ('83456','Beds','54080',3,'In Progress'),  ('83456','Beds','54079',5,'In Progress'),('83456','Beds','54078',2,'Completed'),  ('83456','Beds','54077',1,'In Progress'),  ('83456','Beds','54076',4,'In Progress'),
('83456','Beds','54075',5,'In Progress'),  ('83456','Beds','54074',2,'In Progress'),  ('83456','Beds','54073',5,'Completed'),('83456','Beds','54072',1,'Completed'),  ('83456','Beds','54071',3,'Completed'),  ('83456','Beds','54070',4,'In Progress'),
('83456','Beds','54069',2,'In Progress'),  ('83456','Beds','54068',1,'In Progress'),  ('83456','Beds','54067',5,'In Progress'),('83456','Beds','54066',2,'In Progress'),  ('83456','Beds','54065',4,'Completed'), ('83456','Beds','54064',1,'Completed'),
('83456','Beds','54063',3,'In Progress'),  ('83456','Beds','54062',5,'Completed'), ('83456','Beds','54061',4,'In Progress'),('83456','Beds','54060',2,'In Progress'),  ('83456','Beds','54059',5,'In Progress'), ('83456','Beds','54058',1,'In Progress'),
('83456','Beds','54057',4,'In Progress'),  ('83456','Beds','54056',3,'In Progress'), ('83456','Beds','54055',5,'In Progress'),('83456','Beds','54054',2,'In Progress'),  ('83456','Beds','54053',4,'In Progress'), ('83456','Beds','54052',1,'In Progress'),
('83456','Beds','54051',3,'In Progress'),  ('83456','Beds','54050',5,'In Progress'), ('83456','Beds','54049',2,'In Progress'),('83456','Beds','54048',4,'In Progress'),  ('83456','Beds','54047',1,'In Progress'), ('83456','Beds','54046',5,'In Progress'),
('91234','Pereshable Goods','54046',50,'In Progress'),('91234','Pereshable Goods','54045',12,'In Progress'), ('91234','Pereshable Goods','54044',8,'In Progress'), ('91234','Pereshable Goods','54043',19,'In Progress'),
('91234','Pereshable Goods','54042',170,'In Progress'), ('91234','Pereshable Goods','54041',300,'In Progress'), ('91234','Pereshable Goods','54040',20,'In Progress'),('91234','Pereshable Goods','54039',9,'Completed'), ('91234','Pereshable Goods','54038',14,'In Progress'), ('91234','Pereshable Goods','54037',2,'In Progress'),
('91234','Pereshable Goods','54036',11,'Completed'), ('91234','Pereshable Goods','54035',19,'In Progress'), ('91234','Pereshable Goods','54034',6,'In Progress'),('91234','Pereshable Goods','54033',13,'In Progress'), ('91234','Pereshable Goods','54032',8,'Completed'), ('91234','Pereshable Goods','54031',20,'In Progress'),
('91234','Pereshable Goods','54030',5,'In Progress'), ('91234','Pereshable Goods','54029',180,'In Progress'), ('91234','Pereshable Goods','54028',1,'In Progress'),('91234','Pereshable Goods','54027',16,'In Progress'), ('91234','Pereshable Goods','54026',7,'Completed'), ('91234','Pereshable Goods','54025',10,'In Progress'),
('91234','Pereshable Goods','54024',4,'In Progress'), ('91234','Pereshable Goods','54023',15,'In Progress'), ('91234','Pereshable Goods','54022',12,'In Progress'),('91234','Pereshable Goods','54021',17,'In Progress'), ('91234','Pereshable Goods','54020',9,'In Progress'), ('91234','Pereshable Goods','54019',3,'In Progress'),
('91234','Pereshable Goods','54018',20,'Completed'), ('91234','Pereshable Goods','54017',14,'In Progress'), ('91234','Pereshable Goods','54016',6,'In Progress'),('91234','Pereshable Goods','54015',2,'Completed'), ('91234','Pereshable Goods','54014',11,'Completed'), ('91234','Pereshable Goods','54013',19,'In Progress'),
('91234','Pereshable Goods','54012',13,'In Progress'), ('91234','Pereshable Goods','54011',7,'In Progress'), ('91234','Pereshable Goods','54010',18,'In Progress'),('91234','Pereshable Goods','54009',1,'In Progress'), ('91234','Pereshable Goods','54008',16,'In Progress'), ('91234','Pereshable Goods','54007',5,'In Progress'),
('91234','Pereshable Goods','54006',12,'Completed'), ('91234','Pereshable Goods','54005',8,'In Progress'), ('91234','Pereshable Goods','54004',20,'In Progress'),('91234','Pereshable Goods','54003',4,'In Progress'), ('91234','Pereshable Goods','54002',17,'In Progress'), ('91234','Pereshable Goods','54001',10,'In Progress'),
('91234','Pereshable Goods','54000',3,'In Progress'), ('91234','Pereshable Goods','53999',15,'In Progress'), ('91234','Pereshable Goods','53998',6,'In Progress'),('91234','Pereshable Goods','53997',19,'In Progress'), ('91234','Pereshable Goods','53996',2,'In Progress'), ('91234','Pereshable Goods','53995',14,'In Progress'),
('91234','Pereshable Goods','53994',9,'Completed'), ('91234','Pereshable Goods','53993',11,'In Progress'), ('91234','Pereshable Goods','53992',13,'Completed'),('91234','Pereshable Goods','53991',5,'Completed'), ('91234','Pereshable Goods','53990',18,'In Progress'), ('91234','Pereshable Goods','53989',7,'In Progress'),
('91234','Pereshable Goods','53988',16,'In Progress'), ('91234','Pereshable Goods','53987',1,'In Progress'), ('91234','Pereshable Goods','53986',20,'Completed'),('91234','Pereshable Goods','53985',12,'In Progress'), ('91234','Pereshable Goods','53984',8,'In Progress'), ('91234','Pereshable Goods','53983',17,'In Progress'),
('91234','Pereshable Goods','53982',4,'In Progress'), ('70123','Toys','53982',10,'In Progress'),('70123','Toys','53981',12,'In Progress'), ('70123','Toys','53980',5,'In Progress'), ('70123','Toys','53979',19,'Completed'),
('70123','Toys','53978',80,'In Progress'),  ('70123','Toys','53977',16,'In Progress'),('70123','Toys','53976',30,'In Progress'),  ('70123','Toys','53975',18,'In Progress'),('70123','Toys','53974',7,'Completed'),   ('70123','Toys','53973',20,'In Progress'), ('70123','Toys','53972',2,'In Progress'),('70123','Toys','53971',9,'Completed'),   ('70123','Toys','53970',16,'In Progress'), ('70123','Toys','53969',11,'In Progress'),
('70123','Toys','53968',50,'In Progress'),  ('70123','Toys','53967',13,'Completed'),  ('70123','Toys','53966',40,'In Progress'),('70123','Toys','53965',17,'In Progress'), ('70123','Toys','53964',8,'In Progress'),  ('70123','Toys','53963',19,'Completed'),
('70123','Toys','53962',10,'In Progress'),  ('70123','Toys','53961',15,'In Progress'), ('70123','Toys','53960',60,'In Progress'),('70123','Toys','53959',12,'In Progress'), ('70123','Toys','53958',20,'In Progress'), ('70123','Toys','53956',10,'In Progress'),
('70123','Toys','53955',20,'In Progress'),  ('70123','Toys','53954',14,'In Progress'), ('70123','Toys','53953',30,'In Progress'),('70123','Toys','53952',13,'In Progress'), ('70123','Toys','53951',17,'In Progress'), ('70123','Toys','53950',9,'In Progress'),
('70123','Toys','53949',60,'Completed'),   ('70123','Toys','53948',11,'In Progress');

INSERT INTO AID_Request (Victim_ID, Resource_ID, Request_ID, Status) VALUES
('010001','10023','20034','In Progress'),  ('010002','10023','21234','In Progress'),  ('010003','12345','22345','Completed'),('020001','12340','54321','In Progress'),  ('020002','12341','54320','In Progress'),  ('020003','12342','54319','In Progress'),
('020004','12343','54318','In Progress'),  ('020005','12344','54317','In Progress'),  ('020006','12345','54316','In Progress'),('030002','12346','54315','Completed'),    ('030003','12347','54314','In Progress'),  ('030004','12348','54313','Completed'),('030005','12349','54312','In Progress'),  ('030006','12350','54311','In Progress'),  ('040001','12351','54310','In Progress'),
('040002','12352','54309','In Progress'),  ('040003','12353','54308','Completed'),    ('040004','12354','54307','In Progress'),('040005','12355','54306','In Progress'),  ('050001','12356','54305','In Progress'),  ('050002','12357','54304','In Progress'),
('050003','12358','54303','In Progress'),  ('050004','12359','54302','In Progress'),  ('050005','12360','54301','In Progress'),('070711','12419','54241','In Progress'),  ('073527','12420','54240','Completed'),  ('071584','12421','54239','In Progress'),
('075635','12423','54238','In Progress'),  ('076224','12424','54237','In Progress'),  ('077527','12425','54236','In Progress'),('079891','12426','54235','Completed'),  ('072547','12427','54234','In Progress'),  ('074333','12428','54233','In Progress'),('075881','12429','54232','Completed'),  ('075574','12430','54231','In Progress'),  ('081535','12431','54230','In Progress'),
('086912','12432','54229','In Progress'),  ('080520','12433','54228','In Progress'),  ('083582','12434','54227','Completed'),('080488','12435','54226','In Progress'), ('099891','12436','54225','In Progress'),  ('096201','12437','54224','In Progress'),  ('095881','12438','54223','Completed'),
('092045','12439','54221','In Progress'),  ('091584','12440','54220','In Progress'),  ('091674','12441','54219','In Progress'),('097527','12442','54218','In Progress'),  ('094333','12443','54217','Completed'),  ('099459','12445','54216','In Progress'),
('091519','12446','54215','In Progress'),  ('095635','12447','54214','In Progress'),  ('094741','12448','54213','In Progress'),('094803','12449','54212','Completed'),  ('091139','12450','54211','In Progress'),  ('090711','12451','54210','In Progress'),
('093814','12452','54209','In Progress'),  ('099044','12453','54208','Completed'),  ('093150','12454','54207','In Progress'),('096224','12455','54206','In Progress'),  ('098785','12456','54205','In Progress'),  ('095925','12457','54204','In Progress'),
('093733','12458','54203','Completed'),  ('090750','12459','54202','In Progress'),  ('091291','12460','54201','In Progress'),('091307','12461','54200','In Progress'),  ('100054','12462','54199','In Progress'),  ('100055','12463','54198','Completed'),
('090001','12464','54197','In Progress'),  ('090002','12465','54196','In Progress'),  ('090003','12466','54195','In Progress'),('090004','12467','54194','In Progress'), ('130434','12499','54162','In Progress'),('136873','12500','54161','In Progress'),
('140027','12501','54160','Completed'), ('142615','12502','54159','In Progress'), ('145524','12503','54158','In Progress'),('151144','12504','54157','In Progress'), ('151435','12505','54156','Completed'), ('154016','12506','54155','In Progress'),
('164133','12507','54154','In Progress'), ('167564','12508','54153','In Progress'), ('162223','12509','54152','In Progress'),('165733','12510','54151','Completed'), ('167449','12511','54150','In Progress'), ('164558','12512','54149','In Progress'),
('163467','12513','54148','In Progress'), ('160853','12514','54147','In Progress'), ('165355','12515','54146','In Progress'),('167705','12516','54145','Completed'), ('167022','12517','54144','In Progress'), ('163673','12518','54143','In Progress'),
('161341','12519','54142','In Progress'), ('165529','12520','54141','Completed'), ('160823','12521','54140','In Progress'),('161124','12522','54139','In Progress'), ('166211','12523','54138','In Progress'), ('164262','12524','54137','In Progress'),
('166906','12525','54136','In Progress'), ('160317','12526','54135','Completed'), ('162977','12527','54134','In Progress'),('161375','12528','54133','In Progress'), ('165363','12529','54132','In Progress'), ('168837','12530','54131','In Progress'),
('175313','12531','54130','Completed'), ('173814','12532','54129','In Progress'), ('174374','12533','54128','In Progress'),('171796','12534','54127','In Progress'), ('179197','12535','54126','In Progress'),('172621','12536','54125','Completed'),
('172677','12537','54124','In Progress'), ('173456','12538','54123','In Progress'), ('172266','12539','54122','In Progress'),('173752','12540','54121','In Progress'), ('174741','12541','54120','In Progress'),('176227','12542','54119','In Progress'),
('175168','12543','54118','In Progress'), ('176304','12544','54117','Completed'), ('178751','12545','54116','In Progress'),('174889','12546','54115','In Progress'), ('171743','12547','54114','In Progress'), ('178317','12548','54113','Completed'),
('183258','12549','54112','In Progress'), ('186126','12550','54111','In Progress'), ('188837','12551','54110','In Progress'),('180009','12552','54109','Completed'), ('185310','12553','54108','In Progress'), ('180319','12554','54107','In Progress'),
('185947','12555','54106','In Progress'), ('183923','12556','54105','Completed'),('183946','12557','54104','In Progress'),('181290','12558','54103','In Progress'), ('187962','12559','54102','In Progress'), ('188727','12560','54101','In Progress'),
('190001','12561','54100','In Progress'), ('190002','12562','54099','In Progress'),('190003','12563','54098','In Progress'),('190004','12564','54097','In Progress'),('190005','12565','54096','In Progress'),('200001','12566','54095','Completed'),
('200002','12567','54094','In Progress'),('200003','12568','54093','In Progress'),('200004','12569','54092','In Progress'),('200005','12570','54091','Completed'),('210001','12571','54090','In Progress'),('210002','12572','54089','In Progress'),
('210003','12573','54088','Completed'),('210004','12574','54087','In Progress'),('210005','12575','54086','In Progress'),('220001','12576','54085','In Progress'),('220002','12577','54084','Completed'),('220003','12578','54083','In Progress'),
('220004','12579','54082','In Progress'),('220005','12580','54081','In Progress'),('230001','12581','54080','In Progress'),('230002','12582','54079','In Progress'),('230003','12583','54078','Completed'),('230004','12584','54077','In Progress'),
('230005','12585','54076','In Progress'),('240001','12586','54075','In Progress'),('240002','12587','54074','In Progress'),('240003','12588','54073','Completed'),('240004','12589','54072','Completed'),('240005','12590','54071','Completed'),
('250001','12591','54070','In Progress'),('250002','12592','54069','In Progress'),('250003','12593','54068','In Progress'),('250004','12594','54067','In Progress'),('250005','12595','54066','In Progress'),('260001','12596','54065','Completed'),
('260002','12597','54064','Completed'),('260003','12598','54063','In Progress'),('260004','12599','54062','Completed'),('260005','12600','54061','In Progress'),('270001','12601','54060','In Progress'),('270002','12602','54059','In Progress'),
('270003','12603','54058','In Progress'),('270004','12604','54057','In Progress'),('270005','12605','54056','In Progress'),('280001','12606','54055','In Progress'),('280002','12607','54054','In Progress'),('280003','12608','54053','In Progress'),
('280004','12609','54052','In Progress'),('280005','12610','54051','In Progress'),('290001','12611','54050','In Progress'),('290002','12612','54049','In Progress'),('290003','12613','54048','In Progress'),('290004','12614','54047','In Progress'),
('290005','12615','54046','In Progress'),('300001','12616','54045','In Progress'),('300002','12617','54044','In Progress'),('300003','12618','54043','In Progress'),('300004','12619','54042','In Progress'),('310005','12620','54041','In Progress'),
('310006','12621','54040','In Progress'),('310007','12622','54039','Completed'),('310008','12623','54038','In Progress'),('310009','12624','54037','In Progress'),('320001','12625','54036','Completed'),('320002','12626','54035','In Progress'),
('320003','12627','54034','In Progress'),('320004','12628','54033','In Progress'),('320005','12629','54032','Completed'),('320006','12630','54031','In Progress'),('330001','12631','54030','In Progress'),('330002','12632','54029','In Progress'),
('330003','12633','54028','In Progress'),('330004','12634','54027','In Progress'),('330005','12635','54026','Completed'),('330006','12636','54025','In Progress'),('340001','12637','54024','In Progress'),('340002','12638','54023','In Progress'),
('340003','12639','54022','In Progress'),('340004','12640','54021','In Progress'),('340005','12641','54020','In Progress'),('350001','12642','54019','In Progress'),('350002','12643','54018','Completed'),('350003','12644','54017','In Progress'),
('350004','12645','54016','In Progress'),('350005','12646','54015','Completed'),('350006','12647','54014','Completed'),('360001','12648','54013','In Progress'),
('360002','12649','54012','In Progress'),('360003','12650','54011','In Progress'),('360004','12651','54010','In Progress'),('360005','12652','54009','In Progress'),('370001','12653','54008','In Progress'),('370002','12654','54007','In Progress'),
('370003','12655','54006','Completed'),('370004','12656','54005','In Progress'),('370005','12657','54004','In Progress'),('380001','12658','54003','In Progress'),
('380002','12659','54002','In Progress'),('380003','12660','54001','In Progress'),('380004','12661','54000','In Progress'),('380005','12662','53999','In Progress'),('390001','12663','53998','In Progress'),('390002','12664','53997','In Progress'),
('390003','12665','53996','In Progress'),('390004','12666','53995','In Progress'),('390005','12667','53994','Completed'),('400001','12668','53993','In Progress'),('400002','12669','53992','Completed'),('400003','12670','53991','Completed'),
('400004','12671','53990','In Progress'),('400005','12672','53989','In Progress'),('410001','12673','53988','In Progress'),('410002','12674','53987','In Progress'),('410003','12675','53986','Completed'),('410004','12676','53985','In Progress'),
('410005','12677','53984','In Progress'),('430001','12678','53983','In Progress'),('430002','12679','53982','In Progress'),('430003','12680','53981','In Progress'),('450006','12681','53980','In Progress'),('460001','12682','53979','Completed'),
('460002','12683','53978','In Progress'),('460003','12684','53977','In Progress'),('460004','12685','53976','In Progress'),('460005','12686','53975','In Progress'),
('460006','12687','53974','Completed'),('470001','12688','53973','In Progress'),('470002','12689','53972','In Progress'),('470003','12690','53971','Completed'),
('470004','12691','53970','In Progress'),('470005','12692','53969','In Progress'),('470021','12693','53968','In Progress'),('470022','12694','53967','Completed'),
('470023','12695','53966','In Progress'),('470024','12696','53965','In Progress'),('470025','12697','53964','In Progress'),('480101','12698','53963','Completed'),
('480102','12699','53962','In Progress'),('480103','12700','53961','In Progress'),('480104','12701','53960','In Progress'),('480105','12702','53959','In Progress'),('490101','12703','53958','In Progress'),
('490102','12704','53956','In Progress'),('490103','12705','53955','In Progress'),('490104','12706','53954','In Progress'),('490105','12707','53953','In Progress'),
('500101','12708','53952','In Progress'),('500102','12709','53951','In Progress'),('500103','12710','53950','In Progress'),('500104','12711','53949','Completed'),('500105','12712','53948','In Progress');

INSERT INTO Disaster_Volunteer (Disaster_ID, Volunteer_ID) VALUES
('WF001','VOL001'),('WF002','VOL008'),('WF002','VOL080'),('WF003','VOL082'),('WF003','VOL018'),('WF003','VOL007'),('WF004','VOL036'),('WF004','VOL049'),('WF005','VOL061'),
('WF006','VOL045'),('WF007','VOL064'),('WF007','VOL020'),('WF007','VOL012'),('WF008','VOL098'),('WF008','VOL044'),('WF008','VOL029'),('WF009','VOL081'),('WF009','VOL100'),
('WF010','VOL035'),('WF010','VOL033'),('WF010','VOL096'),('WF010','VOL099'),('WF011','VOL002'),('WF012','VOL077'),('WF012','VOL086'),('WF013','VOL085'),('WF013','VOL092'),
('WF014','VOL014'),('WF014','VOL030'),('WF015','VOL093'),('WF016','VOL089'),('WF016','VOL075'),('WF016','VOL046'),('WF017','VOL017'),('WF017','VOL065'),('WF017','VOL074'),
('WF017','VOL052'),('WF018','VOL084'),('WF019','VOL056'),('WF019','VOL094'),('WF019','VOL040'),('WF019','VOL038'),('WF020','VOL013'),('WF020','VOL031'),('WF021','VOL060'),
('WF021','VOL053'),('WF021','VOL043'),('WF022','VOL003'),('WF022','VOL019'),('WF023','VOL047'),('WF024','VOL072'),('WF025','VOL059'),('WF026','VOL070'),('WF026','VOL034'),
('WF027','VOL095'),('WF027','VOL097'),('WF028','VOL054'),('WF029','VOL039'),('WF030','VOL055'),('WF030','VOL021'),('WF030','VOL028'),('WF031','VOL069'),('WF031','VOL026'),
('WF031','VOL024'),('WF032','VOL076'),('WF033','VOL011'),('WF033','VOL062'),('WF034','VOL006'),('WF034','VOL079'),('WF035','VOL050'),('WF036','VOL041'),('WF036','VOL073'),
('WF036','VOL091'),('WF037','VOL048'),('WF038','VOL057'),('WF038','VOL005'),('WF038','VOL083'),('WF039','VOL027'),('WF040','VOL025'),('WF040','VOL078'),('WF040','VOL067'),
('WF040','VOL015'),('WF041','VOL010'),('WF042','VOL087'),('WF042','VOL058'),('WF043','VOL090'),('WF043','VOL004'),('WF043','VOL016'),('WF044','VOL088'),('WF045','VOL037'),
('WF046','VOL066'),('WF046','VOL042'),('WF047','VOL023'),('WF048','VOL051'),('WF049','VOL068'),('WF049','VOL071'),('WF049','VOL022'),('WF049','VOL032'),('WF050','VOL009'),('WF050','VOL063');
  
INSERT INTO Assists (Org_ID, Disaster_ID) VALUES
('ORG004','WF001'),('ORG002','WF002'),('ORG005','WF003'),('ORG001','WF004'),('ORG003','WF005'),('ORG002','WF006'),('ORG005','WF007'),('ORG001','WF008'),('ORG004','WF009'),
('ORG003','WF010'),('ORG002','WF011'),('ORG005','WF012'),('ORG001','WF013'),('ORG003','WF014'),('ORG004','WF015'),('ORG005','WF016'),('ORG002','WF017'),('ORG004','WF018'),
('ORG005','WF019'),('ORG001','WF020'),('ORG003','WF021'),('ORG004','WF022'),('ORG005','WF023'),('ORG002','WF024'),('ORG001','WF025'),('ORG003','WF026'),('ORG002','WF027'),
('ORG004','WF028'),('ORG001','WF029'),('ORG005','WF030'),('ORG003','WF031'),('ORG001','WF032'),('ORG005','WF033'),('ORG002','WF034'),('ORG004','WF035'),('ORG001','WF036'),
('ORG005','WF037'),('ORG002','WF038'),('ORG004','WF039'),('ORG003','WF040'),('ORG001','WF041'),('ORG005','WF042'),('ORG002','WF043'),('ORG003','WF044'),('ORG004','WF045'),
('ORG001','WF046'),('ORG002','WF047'),('ORG003','WF048'),('ORG004','WF049'),('ORG003','WF050');

INSERT INTO Uses (Volunteer_ID, Resource_ID) VALUES
('VOL001','70123'), ('VOL008','10023'), ('VOL080','10023'), ('VOL082','70123'), ('VOL018','65234'), ('VOL007','12340'),('VOL036','12340'), ('VOL049','12340'), ('VOL061','70123'), ('VOL045','10023'), ('VOL064','70123'), ('VOL020','70123'),
('VOL012','91234'), ('VOL098','10023'), ('VOL044','91234'), ('VOL029','83456'), ('VOL081','10023'), ('VOL100','10023'),('VOL035','10023'), ('VOL033','12340'), ('VOL096','12340'), ('VOL099','91234'), ('VOL002','91234'), ('VOL077','10023'),
('VOL086','91234'), ('VOL085','12340'), ('VOL092','70123'), ('VOL014','70123'), ('VOL030','70123'), ('VOL093','91234'),('VOL089','83456'), ('VOL075','12340'), ('VOL046','83456'), ('VOL017','91234'), ('VOL065','65234'), ('VOL074','10023'),
('VOL052','12340'), ('VOL084','70123'), ('VOL056','83456'), ('VOL094','65234'), ('VOL040','65234'), ('VOL038','12340'),('VOL013','12340'), ('VOL031','65234'), ('VOL060','10023'), ('VOL053','10023'), ('VOL043','83456'), ('VOL003','10023'),
('VOL019','65234'), ('VOL047','65234'), ('VOL072','91234'), ('VOL059','65234'), ('VOL070','10023'), ('VOL034','70123'),('VOL095','83456'), ('VOL097','91234'), ('VOL054','10023'), ('VOL039','83456'), ('VOL055','10023'), ('VOL021','91234'),
('VOL028','65234'), ('VOL069','70123'), ('VOL026','91234'), ('VOL024','65234'), ('VOL076','91234'), ('VOL011','12340'),('VOL062','70123'), ('VOL006','10023'), ('VOL079','10023'), ('VOL050','70123'), ('VOL041','12340'), ('VOL073','65234'),
('VOL091','10023'), ('VOL048','12340'), ('VOL057','10023'), ('VOL005','83456'), ('VOL083','65234'), ('VOL027','83456'),('VOL025','70123'), ('VOL078','65234'), ('VOL067','12340'), ('VOL015','65234'), ('VOL010','65234'), ('VOL087','12340'),
('VOL058','70123'), ('VOL090','65234'), ('VOL004','70123'), ('VOL016','70123'), ('VOL088','70123'), ('VOL037','10023'),('VOL066','91234'), ('VOL042','70123'), ('VOL023','12340'), ('VOL051','91234'), ('VOL068','70123'), ('VOL071','12340'),
('VOL022','12340'), ('VOL032','83456'), ('VOL009','83456'), ('VOL063','65234');

UPDATE Resource
  SET Request_ID='REQ001'
  WHERE Resource_ID='R001';
  
USE DisasterReliefDB;

SET FOREIGN_KEY_CHECKS = 1;

-- Tables uncomment out to see all tables
SHOW TABLES;
/*
SELECT * FROM Shelter;
SELECT * FROM Victim;
SELECT * FROM Victim_Assistance_Needed;
SELECT * FROM Volunteer;
SELECT * FROM Donation;
SELECT * FROM Resource;
SELECT * FROM Aid_Request;
SELECT * FROM Uses;
SELECT * FROM Organization;
SELECT * FROM Resource_Request;
SELECT * FROM Disaster;
SELECT * FROM Disaster_Volunteer;
SELECT * FROM Assists;
SELECT * FROM Assists;
*/
USE DisasterReliefDB;
-- Gives all information for a person with their name starting in the letter M
SELECT
  v.Victim_ID,
  v.Victim_Name,
  v.Age,
  v.Location,
  v.Shelter_ID,

  ar.Request_ID        AS Aid_Request_ID,
  ar.Status            AS Aid_Request_Status,

  rr.Resource_ID,
  rr.Resource_Name,
  rr.Amount            AS Quantity_Requested,
  rr.Status            AS Resource_Request_Status
FROM Victim AS v
LEFT JOIN Aid_Request AS ar
  ON v.Victim_ID = ar.Victim_ID
LEFT JOIN Resource_Request AS rr
  ON ar.Request_ID = rr.Request_ID
  AND rr.Status IN ('In Progress','Completed')
WHERE v.Victim_Name LIKE 'M%'
LIMIT 0,1000;


-- Calculate the number of victims per shelter, compute occupancy %, and pick the top 5.
SELECT
  s.Shelter_ID,
  s.Shelter_Name,
  COUNT(v.Victim_ID)        AS Victim_Count,
  s.Capacity,
  ROUND(COUNT(v.Victim_ID)/s.Capacity * 100,2) AS Occupancy_Pct
FROM Shelter s
LEFT JOIN Victim v 
  ON s.Shelter_ID = v.Shelter_ID
GROUP BY s.Shelter_ID, s.Shelter_Name, s.Capacity
ORDER BY Victim_Count DESC
LIMIT 5;

SELECT
  r.Resource_ID,
  r.Resource_Name,
  d.Amount                 AS Donated_Amount,
  SUM(rr.Amount)           AS Completed_Amount,
  ROUND(
    SUM(rr.Amount) / d.Amount * 100
  , 2)                      AS Percent_Completed
FROM Resource_Request rr
JOIN Resource         r USING(Resource_ID)
JOIN Donation         d USING(Donation_ID)
WHERE rr.Status = 'Completed'
GROUP BY
  r.Resource_ID,
  r.Resource_Name,
  d.Amount
ORDER BY
  r.Resource_ID;

-- gets total count of resources requested 
SELECT
  rr.Resource_ID,
  r.Resource_Name,
  SUM(rr.Amount) AS Total_Requested
FROM Resource_Request AS rr
JOIN Resource AS r
  ON rr.Resource_ID = r.Resource_ID
GROUP BY
  rr.Resource_ID,
  r.Resource_Name
ORDER BY
  rr.Resource_ID;


-- 0) turn off safe updates
SET SQL_SAFE_UPDATES = 0;

-- changes in process to completed and updates the table 
UPDATE Resource_Request
  SET Status = 'Completed'
  WHERE Status = 'In Progress';

-- gets total and percentage of resources under 50% and the percentage left
SET SQL_SAFE_UPDATES = 1;

SELECT
  r.Resource_ID,
  r.Resource_Name,
  r.Amount               AS Current_Amount,
  d.Amount               AS Total_Amount,
  ROUND(r.Amount / d.Amount * 100, 2) AS Percent_Remaining
FROM Resource AS r
JOIN Donation AS d
  ON r.Donation_ID = d.Donation_ID
WHERE r.Amount < 0.5 * d.Amount;

-- shows how many victims are in a shelter
SELECT
  s.Shelter_ID,
  s.Shelter_Name,
  COUNT(v.Victim_ID) AS Num_Victims
FROM Shelter s
LEFT JOIN Victim v 
  ON s.Shelter_ID = v.Shelter_ID
GROUP BY s.Shelter_ID, s.Shelter_Name;

-- shows disaster victims over 30
SELECT Victim_ID, Victim_Name, Age
FROM Victim
WHERE Age > 30
ORDER BY Age DESC;

-- shows disasters with a severity over 55K
SELECT
  Disaster_ID,
  Disaster_Name,
  Location,
  Severity,
  Start_Date,
  End_Date
FROM Disaster
WHERE Severity > 55000
ORDER BY Severity DESC;





	