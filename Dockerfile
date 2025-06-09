# Dockerfile
# Tomcat 10.x 버전을 JDK 17 기반으로 사용합니다.
# tomcat:10.1-jdk17-openjdk-slim 이미지는 Tomcat 10.1과 OpenJDK 17을 포함합니다.
# 이 이미지는 Docker Hub에서 자동으로 다운로드됩니다.
FROM tomcat:10.1-jdk17-openjdk-slim

# Dockerfile이 빌드될 때 컨테이너 내부의 작업 디렉토리를 지정합니다.
# Tomcat의 웹 애플리케이션 배포 디렉토리입니다.
# 이 경로는 Tomcat 서버가 웹 애플리케이션을 찾고 실행하는 표준 위치입니다.
WORKDIR /usr/local/tomcat/webapps/

# 로컬 PC의 'webapps' 디렉토리 안의 모든 파일과 폴더( 예: ROOT 폴더와 그 안의 index.html )를
# 빌드 중인 Docker 이미지 내부의 '/usr/local/tomcat/webapps/' 디렉토리로 복사합니다.
# COPY <로컬_소스_경로><컨테이너_대상_경로>
# 여기서 '.'는 현재 Dockerfile이 있는 디렉토리(tak-tomcat-aks-project)를 의미합니다.
# COPY webapps/ . 는 tak-tomcat-aks-project/webapps/*를 컨테이너의 /usr/local/tomcat/webapps/로 복사합니다.
COPY webapps/ROOT/ /usr/local/tomcat/webapps/ROOT/

# Tomcat이 기본적으로 리스닝하는 HTTP 포트 8080을 컨테이너 외부에 노출합니다.
# 이 EXPOSE 명령어는 문서화의 목적이 크며, 실제 포트 매핑은 Kubernetes Service에서 이루어집니다.
EXPOSE 8080

# Tomcat 이미지는 기본적으로 서버를 싲가하는 CMD(Command)를 정의하고 있습니다.
# 예를 들어, 내부적으로 ["catalina.sh", "run"]과 같은 명령으로 Tomcat이 실행됩니다.
# 따라서, 이 Dockerfile에서 별도의 CMD를 명시하지 않아도 Tomcat 서버가 자동으로 시작됩니다.
