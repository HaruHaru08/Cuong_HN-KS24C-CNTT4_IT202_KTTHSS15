/*
 * DATABASE SETUP - SESSION 15 EXAM
 * Database: StudentManagement
 */

DROP DATABASE IF EXISTS StudentManagement;
CREATE DATABASE StudentManagement;
USE StudentManagement;

-- =============================================
-- 1. TABLE STRUCTURE
-- =============================================

-- Table: Students
CREATE TABLE Students (
    StudentID CHAR(5) PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    TotalDebt DECIMAL(10,2) DEFAULT 0
);

-- Table: Subjects
CREATE TABLE Subjects (
    SubjectID CHAR(5) PRIMARY KEY,
    SubjectName VARCHAR(50) NOT NULL,
    Credits INT CHECK (Credits > 0)
);

-- Table: Grades
CREATE TABLE Grades (
    StudentID CHAR(5),
    SubjectID CHAR(5),
    Score DECIMAL(4,2) CHECK (Score BETWEEN 0 AND 10),
    PRIMARY KEY (StudentID, SubjectID),
    CONSTRAINT FK_Grades_Students FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    CONSTRAINT FK_Grades_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects(SubjectID)
);

-- Table: GradeLog
CREATE TABLE GradeLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    StudentID CHAR(5),
    OldScore DECIMAL(4,2),
    NewScore DECIMAL(4,2),
    ChangeDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 2. SEED DATA
-- =============================================

-- Insert Students
INSERT INTO Students (StudentID, FullName, TotalDebt) VALUES 
('SV01', 'Ho Khanh Linh', 5000000),
('SV03', 'Tran Thi Khanh Huyen', 0);

-- Insert Subjects
INSERT INTO Subjects (SubjectID, SubjectName, Credits) VALUES 
('SB01', 'Co so du lieu', 3),
('SB02', 'Lap trinh Java', 4),
('SB03', 'Lap trinh C', 3);

-- Insert Grades
INSERT INTO Grades (StudentID, SubjectID, Score) VALUES 
('SV01', 'SB01', 8.5), -- Passed
('SV03', 'SB02', 3.0); -- Failed

-- Câu 1
delimiter //
create trigger tg_CheckScore
before insert on Grades
for each row
begin
 if New.Score < 0 then set New.Score=0;
 end if;
 if New.Score >10 then set New.Score=10;
 end if;
end //
delimiter ;
-- Câu 2
start transaction;
insert into Students(StudentID,FullName) value('SV02','Ha Thi Bich Ngoc');
update Students set TotalDebt=5000000
where StudentID='SV02';
commit;
-- Câu 3
delimiter //
create trigger tg_LogGradeUpdate
after update on Grades
for each row
begin
    if old.Score <> new.Score then
        insert into GradeLog(StudentID, OldScore, NewScore, ChangeDate)
        values (old.StudentID, old.Score, new.Score, now());
    end if;
end //
delimiter ;
-- Câu 4
delimiter //
create procedure sp_PayTuition (
    in p_StudentID varchar(10)
)
begin
    declare v_NewDebt int;
    start transaction;
    update Students
    set TotalDebt = TotalDebt - 2000000
    where StudentID = p_StudentID;
    select TotalDebt into v_NewDebt
    from Students
    where StudentID = p_StudentID;
    if v_NewDebt < 0 then
        rollback;
    else
        commit;
    end if;
end //
delimiter ;
-- Câu 5
delimiter //
create trigger tg_PreventPassUpdate
before update on Grades
for each row
begin
    if OLD.Score >= 4 then
       signal sqlstate '45000' set message_text='Không được sửa điểm sinh viên';
    end if;
end //
delimiter ;
-- Câu 6
delimiter //
create procedure sp_DeleteStudentGrade(
p_StudentID Char(5),
p_SubjectID char(5)
)
begin
	declare p_OldScore decimal(4,2);
    declare p_NewScore decimal(4,2);
    select OldScore into p_OldScore from GradeLog
    where StudentID=p_StudentID;
     select NewScore into p_NewScore from GradeLog
    where StudentID=p_StudentID;
	start transaction;
    insert into GradeLog(StudentID,OldScore,NewScore,ChangeDate)
    value (p_StudentID,p_OldScore,p_NewScore);
    delete from Grades where StudentID=p_StudentID;
    if StudentID<>p_StudentID then 
    signal sqlstate '45000' set message_text='Xóa không thành công';
    rollback;
    end if;
    commit;
end //
delimiter ;