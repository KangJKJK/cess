#!/bin/bash

# 컬러 정의
export RED='\033[0;31m'
export YELLOW='\033[1;33m'
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m'  # No Color

#도커설치
echo -e "${CYAN}Docker 설치 확인 중${NC}"
if command -v docker >/dev/null 2>&1; then
    echo -e "${GREEN}Docker가 이미 설치되어 있습니다${NC}"
else
    echo -e "${RED}Docker가 설치되어 있지 않습니다 Docker를 설치하는 중${NC}"
    sudo apt update && sudo apt install -y curl net-tools
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    echo -e "${GREEN}Docker가 성공적으로 설치되었습니다${NC}"
fi

# 1. 패키지 업데이트 및 필요한 패키지 설치
echo -e "${CYAN}패키지 업데이트 및 필요한 패키지 설치 중${NC}"
sudo apt update && sudo apt install -y ca-certificates curl gnupg ufw && sudo apt install expect

# 2. Docker GPG 키 및 저장소 설정
echo -e "${CYAN}Docker GPG 키 및 저장소 설정 중${NC}"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 3. Docker 설치 (이미 설치된 경우를 처리)
echo -e "${CYAN}Docker 설치 확인 중${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${CYAN}Docker 설치 중${NC}"
    sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io
else
    echo -e "${GREEN}Docker가 이미 설치되어 있습니다${NC}"
fi

# 4. Docker 서비스 활성화 및 시작
echo -e "${CYAN}Docker 서비스 활성화 및 시작 중${NC}"
sudo systemctl enable docker && sudo systemctl start docker

# 6. CESS nodeadm 다운로드 및 설치
echo -e "${CYAN}CESSv0.6.1 다운로드 중${NC}"
wget https://github.com/CESSProject/cess-nodeadm/archive/v0.6.1.tar.gz

echo -e "${CYAN}CESS 압축 해제 중${NC}"
tar -xvzf v0.6.1.tar.gz

# CESS nodeadm 디렉토리로 이동
echo -e "${CYAN}디렉토리 이동 중${NC}"
cd /root/cess-nodeadm-0.6.1 || { echo -e "${RED}디렉토리 이동 실패${NC}"; exit 1; }
echo -e "${BLUE}현재 디렉토리: $(pwd)${NC}"

echo -e "${CYAN}CESS 설치 중${NC}"
sudo ./install.sh

# 사용자 안내 메시지
echo -e "${PURPLE}Cess wallet 생성: https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Ftestnet-rpc0.cess.cloud%2Fws%2F#/explorer${NC}"
echo -e "${CYAN}다음과 같은 안내 메시지가 나오면 ${YELLOW}노란색${NC}${CYAN}과 같이 진행하세요${NC}"

echo -e "${BLUE}1. Enter cess node mode from 'authority/storage/rpcnode'${NC}"
echo -e "${YELLOW}storage${NC}"
echo -e "${BLUE}2. Enter cess storage listener port${NC}"
echo -e "${YELLOW}엔터${NC}"
echo -e "${BLUE}3. Do you need to automatically detect extranet address as endpoint?${NC}"
echo -e "${YELLOW}y${NC}"
echo -e "${BLUE}4. Enter cess rpc ws-url${NC}"
echo -e "${YELLOW}엔터${NC}"
echo -e "${BLUE}5. Enter cess storage earnings account${NC}"
echo -e "${YELLOW}리워드를 받을 지갑 주소${NC}"
echo -e "${BLUE}6. Enter cess storage signature account phrase${NC}"
echo -e "${YELLOW}위와 다른 지갑의 복구문자${NC}"
echo -e "${BLUE}7. Enter cess storage disk path${NC}"
echo -e "${YELLOW}엔터${NC}"
echo -e "${BLUE}8. Enter cess storage space, by GB unit${NC}"
echo -e "${YELLOW}100${NC}"
echo -e "${BLUE}9. Enter the number of CPU cores used for mining${NC}"
echo -e "${YELLOW}Your CPU cores라고 나오는 숫자${NC}"
echo -e "${BLUE}10. Enter the staking account if you use one account to stake multiple nodes${NC}"
echo -e "${YELLOW}엔터${NC}"
echo -e "${BLUE}11. Enter the TEE worker endpoints if you have any${NC}"
echo -e "${YELLOW}엔터${NC}"

# 7. CESS 프로필 및 설정 구성
echo -e "${CYAN}프로필 설정 구성 중${NC}"
sudo cess profile testnet

sleep 2

echo -e "${PURPLE}CESS 구성 설정 중 (사용자 입력 필요)${NC}"
stdbuf -i0 -o0 -e0 sudo cess config set

echo -e "${GREEN}CESS 구성 완료${NC}"

# 8. CESS 노드 구동 및 Docker 로그 확인
echo -e "${CYAN}CESS 노드 구동 및 Docker 로그 확인 중${NC}"
sudo cess start && docker logs miner

# 현재 사용 중인 포트 확인
used_ports=$(netstat -tuln | awk '{print $4}' | grep -o '[0-9]*$' | sort -u)

# 각 포트에 대해 ufw allow 실행
for port in $used_ports; do
    echo -e "${CYAN}포트 ${port}을(를) 허용합니다${NC}"
    sudo ufw allow $port/tcp
done

echo -e "${GREEN}모든 사용 중인 포트가 허용되었습니다${NC}"

echo -e "${BLUE}현재 실행중인 Cess 컨테이너 목록은 다음과 같습니다${NC}"
docker ps | grep cess

echo -e "${CYAN}모든 작업이 완료되었습니다 컨트롤+A+D로 스크린을 종료해주세요${NC}"
echo -e "${GREEN}Faucet 주소: https://cess.network/faucet.html${NC}"
echo -e "${YELLOW}가끔씩 이 명령어를 입력해주세요: sudo cess miner claim${NC}"
echo -e "${PURPLE}스크립트 작성자: https://t.me/kjkresearch${NC}"

