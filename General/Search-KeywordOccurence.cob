IDENTIFICATION DIVISION.
PROGRAM-ID. KeywordCounter.

ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT InputFile ASSIGN TO 'input.txt'
        ORGANIZATION IS LINE SEQUENTIAL.
    SELECT KeywordFile ASSIGN TO 'keywords.txt'
        ORGANIZATION IS LINE SEQUENTIAL.
    SELECT OutputFile ASSIGN TO 'output.txt'
        ORGANIZATION IS LINE SEQUENTIAL.

DATA DIVISION.
FILE SECTION.
FD InputFile.
01 InputRecord PIC X(80).

FD KeywordFile.
01 KeywordRecord PIC X(80).

FD OutputFile.
01 OutputRecord PIC X(80).

WORKING-STORAGE SECTION.
01 WS-EOF-FLAG      PIC X VALUE 'N'.
    88 EndOfFile    VALUE 'Y'.

01 WS-KEYWORD-TABLE.
    05 WS-KEYWORD OCCURS 10 TIMES INDEXED BY IDX.
        10 WS-KEYWORD-TEXT PIC X(20).
        10 WS-KEYWORD-COUNT PIC 9(5).

01 WS-LINE PIC X(80).
01 WS-TEMP PIC X(80).
01 WS-SUBSTR POSITIVE VALUE 1.
01 WS-SUBSTR-END POSITIVE VALUE 80.

PROCEDURE DIVISION.
    OPEN INPUT KeywordFile
    PERFORM Read-Keywords
    CLOSE KeywordFile

    OPEN INPUT InputFile
    OPEN OUTPUT OutputFile

    PERFORM UNTIL EndOfFile
        READ InputFile INTO WS-LINE
        AT END
            SET EndOfFile TO TRUE
        NOT AT END
            PERFORM Process-Line
        END-READ
    END-PERFORM

    PERFORM Write-Results

    CLOSE InputFile
    CLOSE OutputFile
    STOP RUN.

Read-Keywords.
    PERFORM UNTIL EndOfFile
        READ KeywordFile INTO WS-TEMP
        AT END
            SET EndOfFile TO TRUE
        NOT AT END
            MOVE WS-TEMP TO WS-KEYWORD-TEXT (IDX)
            ADD 1 TO IDX
        END-READ
    END-PERFORM
    MOVE 'N' TO WS-EOF-FLAG.

Process-Line.
    MOVE 1 TO IDX
    PERFORM VARYING WS-SUBSTR FROM 1 BY 1 UNTIL WS-SUBSTR > 80
        PERFORM VARYING IDX FROM 1 BY 10
            SEARCH WS-KEYWORD
                WHEN WS-KEYWORD-TEXT (IDX) IS EQUAL TO WS-SUBSTR (WS-SUBSTR:20)
                    ADD 1 TO WS-KEYWORD-COUNT (IDX)
            END-SEARCH
        END-PERFORM
    END-PERFORM.

Write-Results.
    MOVE 1 TO IDX
    PERFORM VARYING IDX FROM 1 BY 1 UNTIL IDX > 10
        STRING WS-KEYWORD-TEXT (IDX) DELIMITED BY SPACE
               " : " DELIMITED BY SIZE
               WS-KEYWORD-COUNT (IDX) DELIMITED BY SIZE
               INTO OutputRecord
        WRITE OutputRecord
    END-PERFORM.