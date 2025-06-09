<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.Date" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tomcat on AKS - Azure SQL DB Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f4f4f4; color: #333; }
        .container { background-color: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 0 10px rgba(0, 0, 0, 0.1); }
        h1 { color: #0056b3; }
        h2 { color: #007bff; }
        .success { color: green; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Tomcat on AKS - Azure SQL Database Test</h1>
        <p>Current Time: <%= new Date() %></p>
        <p>Served by Pod: <%= System.getenv("HOSTNAME") %></p>

        <h2>Database Connection Test:</h2>
        <%
        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;
        String status = "";

        // --- 중요: 이 부분은 나중에 Kubernetes Secret으로 주입될 환경 변수들입니다. ---
        String dbUrl = System.getenv("JDBC_URL");       // 데이터베이스 연결 문자열
        String dbUser = System.getenv("DB_USER");       // 데이터베이스 사용자 이름
        String dbPassword = System.getenv("DB_PASSWORD"); // 데이터베이스 암호
        // ----------------------------------------------------------------------

        if (dbUrl == null || dbUser == null || dbPassword == null) {
            // 환경 변수가 설정되지 않았다면 오류 메시지를 표시합니다.
            status = "<span class='error'>Error: Database connection environment variables are not set! " +
                     "Please check K8s Secret and Deployment configuration.</span>";
        } else {
            try {
                // JDBC 드라이버 로드
                // 이 코드는 특정 드라이버 클래스를 메모리에 로드하여 사용할 준비를 합니다.
                Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");

                // 데이터베이스 연결 시도
                // dbUrl, dbUser, dbPassword를 사용하여 데이터베이스에 연결합니다.
                conn = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
                status = "<span class='success'>Successfully connected to Azure SQL Database!</span>";

                // Statement 객체 생성 (SQL 명령을 실행하기 위해 필요)
                stmt = conn.createStatement();

                // 'messages' 테이블 생성 (만약 없다면)
                // 이 SQL 명령은 'messages'라는 테이블이 존재하지 않을 경우에만 생성합니다.
                // id: 자동 증가하는 기본 키, content: 텍스트 내용, created_at: 생성 시간
                String createTableSql = "IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='messages' AND xtype='U') " +
                                        "CREATE TABLE messages (id INT IDENTITY(1,1) PRIMARY KEY, content VARCHAR(255), created_at DATETIME DEFAULT GETDATE())";
                stmt.executeUpdate(createTableSql); // SQL 명령 실행
                status += "<br/><span class='success'>Table 'messages' ensured (created if not exists).</span>";

                // 데이터 삽입
                // PreparedStatement를 사용하여 SQL 인젝션 공격을 방지하고 안전하게 데이터를 삽입합니다.
                String insertSql = "INSERT INTO messages (content) VALUES (?)";
                PreparedStatement pstmt = conn.prepareStatement(insertSql);
                pstmt.setString(1, "Hello from AKS Pod " + System.getenv("HOSTNAME") + " at " + new Date());
                int rowsAffected = pstmt.executeUpdate(); // 삽입 실행
                status += "<br/><span class='success'>" + rowsAffected + " row(s) inserted.</span>";
                pstmt.close(); // PreparedStatement 닫기

                // 데이터 조회
                // 'messages' 테이블의 모든 데이터를 조회하여 웹 페이지에 테이블 형태로 보여줍니다.
                status += "<h2>Messages from DB:</h2>";
                status += "<table><tr><th>ID</th><th>Content</th><th>Created At</th></tr>";
                rs = stmt.executeQuery("SELECT id, content, created_at FROM messages ORDER BY id DESC"); // 조회 실행
                while (rs.next()) { // 결과 집합을 한 줄씩 읽어옵니다.
                    status += "<tr><td>" + rs.getInt("id") + "</td><td>" + rs.getString("content") + "</td><td>" + rs.getTimestamp("created_at") + "</td></tr>";
                }
                status += "</table>";

            } catch (Exception e) {
                // 데이터베이스 연결 또는 작업 중 오류가 발생하면 오류 메시지를 표시합니다.
                status = "<span class='error'>Failed to connect or operate on Azure SQL Database: " + e.getMessage() + "</span>";
                e.printStackTrace(); // Pod의 로그에 상세 오류 스택 트레이스 출력 (디버깅용)
            } finally {
                // 데이터베이스 연결 자원(ResultSet, Statement, Connection)을 안전하게 해제합니다.
                // 리소스 누수를 방지하기 위해 매우 중요합니다.
                try { if (rs != null) rs.close(); } catch (SQLException se) { /* ignore */ }
                try { if (stmt != null) stmt.close(); } catch (SQLException se) { /* ignore */ }
                try { if (conn != null) conn.close(); } catch (SQLException se) { /* ignore */ }
            }
        }
        out.println(status); // 최종 결과를 웹 페이지에 출력합니다.
        %>
    </div>
</body>
</html>
