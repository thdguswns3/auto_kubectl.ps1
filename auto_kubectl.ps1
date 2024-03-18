#################################################################################################################
# 제작자: 송현준
# Description: 팀 업무 편의를 위해 작성된 파워쉘 스크립트로 kubectl에서 지원되지 않는 기능 또는 업무 자동화 목적
#################################################################################################################

# 변수 설정
$Last_Updated = "23.10.10"
$VERSION = "2.0.5"
$KUBECONFIG = "$HOME\Desktop\kubeconfig"
$KUBECONFIG_FILES = @()
$NAMESPACE_LIST = @()

# Kubectl이 설치되어 있는지 확인 -> 설치 안되어 있는 경우 안내 메시지 출력 후 스크립트 종료
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "kubectl이 설치되어있지 않습니다. kubectl을 설치 후 스크립트를 다시 실행해주세요." -ForegroundColor Red
    exit 0
}

# KUBECONFIG 디렉터리가 없는 경우 디렉터리 생성 후 안내 메시지 출력
if (-not (Test-Path $KUBECONFIG)) {
    New-Item -ItemType Directory -Path $KUBECONFIG
    Write-Host "Please copy all of the kubeconfig files to the following path: " -NoNewline; Write-Host "$KUBECONFIG" -ForegroundColor Green
    exit 0
}

# kubeconfig 파일이 존재하지 않을 경우 알림 메시지 출력
if (-not (Test-Path $KUBECONFIG\*kubeconfig*)) {
    Write-Host "kubeconfig 파일이 $KUBECONFIG\ 경로에 존재하지 않습니다. 파일 이름에 kubeconfig 를 반드시 포함하세요." -ForegroundColor Red
    exit 0
}

# 스크립트 버전 및 업데이트 날짜 출력
Write-Host "Version: " -NoNewline; Write-Host "${VERSION} " -NoNewline -ForegroundColor Green; Write-Host "/ Last Updated at " -NoNewline; Write-Host "${Last_Updated}" -ForegroundColor Green;

# edit권한의 Kubeconfig 파일에서 네임스페이스 파싱 -> 사용자에게 네임스페이스 출력해줄 때 사용
Select-String -Path "$KUBECONFIG\*edit*" -Pattern "namespace" | foreach-object {
    $KUBECONFIG_FILE = $_.Filename
    $LINE = $_.Line
    $NAMESPACES = $line.Substring($LINE.IndexOf(":") + 2)
    $KUBECONFIG_FILES += $KUBECONFIG_FILE
    $NAMESPACE_LIST += $NAMESPACES
}

# 수행할 작업 목록 해시테이블 (Ordered)
$CHOICES = [ordered]@{
    ' 1.' = '리소스 설정/상태 점검 및 모니터링'
    ' 2.' = '로그 출력/다운로드'
    ' 3.' = 'Java 명령어 모음'
    ' 4.' = 'Jeus Admin 명령어 모음'
    ' 5.' = '파드 쉘 접속'
    ' 6.' = 'Network Policy 자동 생성(SKE 개발자 가이드)'
    ' 7.' = '파일 복사 (컨테이너 <-> 로컬 PC)'
    ' 8.' = 'DB 커넥션 테스트'
}

$CHOICES_STATUS_CHECK = [ordered]@{
    ' 1.' = '모든 네임스페이스의 POD CPU/Memory 점유 상태 조회'
    ' 2.' = '특정 네임스페이스의 Pod CPU/Memory 점유 상태 조회'
    ' 3.' = 'CPU, Memory 실시간 모니터링'
    ' 4.' = '전체 네임스페이스 상태 점검'
    ' 5.' = 'Deployment CPU, Memory 설정 확인'
    ' 6.' = 'Ingress Annotation 설정 확인(Timeout 설정 등)'
    ' 7.' = '프로세스 모니터링 (ps aufxww)'
}

$CHOICES_LOG = [ordered]@{
    ' 1.' = '파드 로그 출력(Tail)'
    ' 2.' = '파드 로그 로컬 다운로드'
    ' 3.' = 'Nginx Ingress Controller 로그 실시간 확인(access.log, error.log)'
}

$CHOICES_JAVA = [ordered]@{
    ' 1.' = 'JSTAT 확인'
    ' 2.' = 'JVM Heap 덤프 파일 로컬 다운로드'
    ' 3.' = 'jinfo 확인'
    ' 4.' = 'jstack 확인'
}

$CHOICES_JEUS_ADMIN = [ordered]@{
    ' 1.' = 'jeus_admin 접속'
    ' 2.' = 'corelated server 조회'
    ' 3.' = 'show-web-statistics 확인'
    ' 4.' = 'server information 조회'
    ' 5.' = 'list-servers 확인'
}

# 작업 선택
function SelectJob {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $STEP
    )
    
    # 사용자가 유효하지 않은 선택을 할 경우 SelectJob 함수를 처음부터 실행하도록 하기 위해 While문 사용
    while(1){
        Switch($STEP){

            # 작업 선택
            '0'{

                # "작업 선택" 단계 알림 메시치 출력
                Write-Host "-------작업 선택-------" -BackgroundColor Yellow -ForegroundColor Red

                # 사용자에게 작업 목록 출력
                foreach ($CHOICE in $CHOICES.GetEnumerator()) {
                Write-Host "$($CHOICE.Key) $($CHOICE.Value)"
                }

                # q를 입력하면 스크립트가 종료된다는 메시지 출력
                Write-Host "Type " -NoNewline
                Write-Host "'q'"  -ForegroundColor Magenta -NoNewline
                Write-Host " to quit this script"

                # 사용자의 작업 선택을 입력 받아 변수 할당
                while(1){
                    $JOB = Read-Host "Choose an action"
                    if($JOB -ne '') {
                        break
                    }
                }

                # q을 입력할 경우 스크립트 종료
                if ($JOB -eq "q") {
                    exit 0
                }

                # 사용자가 유효하지 않은 값을 입력할 경우 안내 메시지 출력 후 SelectJob 다시 실행
                elseif (![int]::TryParse($JOB, [ref]$null) -or [int]${JOB} -lt 1 -or [int]${JOB} -gt $($CHOICES.Count) ) {
                    Write-Host "Invalid selection. Please enter a number between 1 and $($CHOICES.Count)" -ForegroundColor Red
                    continue
                }
                
                # 리소스 설정/상태 점검 단계로 이동
                elseif( $JOB -eq "1") {
                    $STEP = 1
                    continue
                }

                # 로그 출력/다운로드 단계로 이동
                elseif( $JOB -eq "2") {
                    $STEP = 2
                    continue
                }
                
                # Java 명령어 모음 단계로 이동
                elseif( $JOB -eq "3") {
                    $STEP = 3
                    continue
                }

                # Jeus Admin 명령어 모음 단계로 이동
                elseif( $JOB -eq "4") {
                    Number0_4 -ORDER 1
                    continue
                }

                # 파드 쉘 접속
                elseif( $JOB -eq "5") {
                    Number0_5 -ORDER 1
                    continue
                }
                
                # Network Policy 자동 생성(SKE 개발자 가이드)
                elseif( $JOB -eq "6") {
                    Number0_6 -ORDER 1
                    continue
                }

                # 파일 복사 (컨테이너 <-> 로컬 PC)
                elseif( $JOB -eq "7") {
                    Number0_7 -ORDER 1
                    continue
                }

                # DB 커넥션 테스트
                elseif( $JOB -eq "8") {
                    Number0_8 -ORDER 1
                    continue
                }
            }

            # 리소스 설정/상태 점검 및 모니터링
            '1'{

                # "리소스 설정/상태 점검 선택" 단계 알림 메시치 출력
                Write-Host "-------리소스 설정/상태 점검 작업 선택-------" -BackgroundColor Yellow -ForegroundColor Red

                # 사용자에게 작업 목록 출력
                foreach ($CHOICE in $CHOICES_STATUS_CHECK.GetEnumerator()) {
                Write-Host "$($CHOICE.Key) $($CHOICE.Value)"
                }

                # 안내 메시지 출력
                Message_Quit_Back


                # 사용자의 작업 선택을 입력 받아 변수 할당
                while(1){
                    $JOB = Read-Host "Choose an action"
                    if($JOB -ne '') {
                        break
                    }
                }

                # q을 입력할 경우 스크립트 종료
                if ($JOB -eq "q") {
                    exit 0
                }

                # b를 입력할 경우 뒤로가기
                elseif($JOB -eq "b") {
                    $STEP = 0
                    continue
                }

                # 사용자가 유효하지 않은 값을 입력할 경우 안내 메시지 출력 후 SelectJob 다시 실행
                elseif (![int]::TryParse($JOB, [ref]$null) -or [int]${JOB} -lt 1 -or [int]${JOB} -gt $($CHOICES_STATUS_CHECK.Count) ) {
                    Write-Host "Invalid selection. Please enter a number between 1 and $($CHOICES_STATUS_CHECK.Count)" -ForegroundColor Red
                    continue
                }

                # 모든 네임스페이스의 POD CPU/Memory 점유 상태 조회
                elseif($JOB -eq 1){
                    Number1_1
                }

                # 특정 네임스페이스의 Pod CPU/Memory 점유 상태 조회
                elseif($JOB -eq 2){
                    $STEP = Number1_2 -ORDER 1
                    continue
                }

                # CPU, Memory 실시간 모니터링
                elseif($JOB -eq 3){
                    $STEP = Number1_3 -ORDER 1
                    continue
                }

                # 전체 네임스페이스 상태 점검
                elseif($JOB -eq 4){
                    Number1_4
                }

                # Deployment CPU, Memory 설정 확인
                elseif($JOB -eq 5){
                    $STEP = Number1_5 -ORDER 1
                    continue
                }

                # Ingress Annotation 설정 확인(Timeout 설정 등)
                elseif($JOB -eq 6){
                    $STEP = Number1_6 -ORDER 1
                    continue
                }
                
                # 프로세스 모니터링 (ps aufxww)
                elseif($JOB -eq 7){
                    $STEP = Number1_7 -ORDER 1
                    continue
                }
            }

            # 로그 출력/다운로드
            '2'{

                # "로그 출력/다운로드" 단계 알림 메시치 출력
                Write-Host "-------로그 출력/다운로드 작업 선택-------" -BackgroundColor Yellow -ForegroundColor Red

                # 사용자에게 작업 목록 출력
                foreach ($CHOICE in $CHOICES_LOG.GetEnumerator()) {
                Write-Host "$($CHOICE.Key) $($CHOICE.Value)"
                }

                # 안내 메시지 출력
                Message_Quit_Back

                # 사용자의 작업 선택을 입력 받아 변수 할당
                while(1){
                    $JOB = Read-Host "Choose an action"
                    if($JOB -ne '') {
                        break
                    }
                }

                # q을 입력할 경우 스크립트 종료
                if ($JOB -eq "q") {
                    exit 0
                }

                # b를 입력할 경우 뒤로가기
                elseif($JOB -eq "b") {
                    $STEP = 0
                    continue
                }

                # 사용자가 유효하지 않은 값을 입력할 경우 안내 메시지 출력 후 SelectJob 다시 실행
                elseif (![int]::TryParse($JOB, [ref]$null) -or [int]${JOB} -lt 1 -or [int]${JOB} -gt $($CHOICES_LOG.Count) ) {
                    Write-Host "Invalid selection. Please enter a number between 1 and $($CHOICES_LOG.Count)" -ForegroundColor Red
                    continue
                }

                # 파드 로그 출력(Tail)
                elseif($JOB -eq 1){
                    $STEP = Number2_1 -ORDER 1
                    continue
                }

                # 파드 로그 로컬 다운로드
                elseif($JOB -eq 2){
                    $STEP = Number2_2 -ORDER 1
                    continue
                }

                # Nginx Ingress Controller 로그 실시간 확인(access.log, error.log)
                elseif($JOB -eq 3){
                    $STEP = Number2_3 -ORDER 1
                    continue
                }
            }

            # Java 명령어 모음
            '3' {

                # "Java 명령어 모음" 단계 알림 메시치 출력
                Write-Host "-------Java 명령어 모음 작업 선택-------" -BackgroundColor Yellow -ForegroundColor Red

                # 사용자에게 작업 목록 출력
                foreach ($CHOICE in $CHOICES_JAVA.GetEnumerator()) {
                Write-Host "$($CHOICE.Key) $($CHOICE.Value)"
                }

                # 안내 메시지 출력
                Message_Quit_Back

                # 사용자의 작업 선택을 입력 받아 변수 할당
                while(1){
                    $JOB = Read-Host "Choose an action"
                    if($JOB -ne '') {
                        break
                    }
                }

                # q을 입력할 경우 스크립트 종료
                if ($JOB -eq "q") {
                    exit 0
                }

                # b를 입력할 경우 뒤로가기
                elseif($JOB -eq "b") {
                    $STEP = 0
                    continue
                }

                # 사용자가 유효하지 않은 값을 입력할 경우 안내 메시지 출력 후 SelectJob 다시 실행
                elseif (![int]::TryParse($JOB, [ref]$null) -or [int]${JOB} -lt 1 -or [int]${JOB} -gt $($CHOICES_JAVA.Count) ) {
                    Write-Host "Invalid selection. Please enter a number between 1 and $($CHOICES_JAVA.Count)" -ForegroundColor Red
                    continue
                }
                
                # JSTAT 확인
                elseif($JOB -eq 1){
                    $STEP = Number3_1 -ORDER 1
                    continue
                }

                # JVM Heap 덤프 파일 로컬 다운로드
                elseif($JOB -eq 2){
                    $STEP = Number3_2 -ORDER 1
                    continue
                }

                # jinfo 확인
                elseif($JOB -eq 3){
                    $STEP = Number3_3 -ORDER 1
                    continue
                }

                # jstack 확인
                elseif($JOB -eq 4){
                    $STEP = Number3_4 -ORDER 1
                    continue
                }
            }
        }
    }
}

# 네임스페이스 선택
function NamespaceSelect {
    while(1){

        # "네임스페이스 선택" 단계 알림 메시치 출력
        Write-Host "-------네임스페이스 선택-------" -BackgroundColor Yellow -ForegroundColor Red

        # 사용자가 잘못된 값 입력하여 while문 처음부터 수행할 때 변수 값을 0으로 초기화
        [int]$NAMESPACE_COUNT = 0

        # 사용자에게 선택 가능한 네임스페이스 출력
        foreach ($PARSING_NAMESPACE in ${NAMESPACE_LIST}) {
            $NAMESPACE_COUNT++
            Write-Host "${NAMESPACE_COUNT}: $PARSING_NAMESPACE"
        }

        Message_Quit_Back

        # 사용자의 네임스페이스 선택을 입력 받아 변수에 할당
        while(1){
            $NAMESPACE_SELECTION = Read-Host "Choose a namespace"
            if($NAMESPACE_SELECTION -ne '') {
                break
            }
        }

        # q를 입력할 경우 스크립트 종료
        if (${NAMESPACE_SELECTION} -eq "q") {
            Write-Host "Quit this script" -ForegroundColor Yellow
            exit 0
        }

        # b를 입력할 경우 이전 단계로 이동
        elseif (${NAMESPACE_SELECTION} -eq "b") {
            Write-Host "Return to the previous step" -ForegroundColor Yellow
            return 4
        }

        # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
        elseif (![int]::TryParse(${NAMESPACE_SELECTION}, [ref]$null) -or [int]${NAMESPACE_SELECTION} -lt 1 -or [int]${NAMESPACE_SELECTION} -gt $($NAMESPACE_LIST.Count) ) {
            Write-Host "Invalid selection. Please enter a number between 1 and $($NAMESPACE_LIST.Count)" -ForegroundColor Red
            continue
        }

        # 사용자가 유효한 값을 입력한 경우
        else{
            # 사용자가 유효한 값을 입력하면 선택한 네임스페이스를 $NAMESPACE 변수에 할당
            $global:NAMESPACE = $($NAMESPACE_LIST[${NAMESPACE_SELECTION}-1])
            Write-Host "Selected ${global:NAMESPACE}"

            # 네임스페이스 선택에 따라 Kubeconfig 파일 경로를 $KUBECONFIG_PATH에 변수로 설정
            $global:KUBECONFIG_PATH = "${KUBECONFIG}\$($KUBECONFIG_FILES[${NAMESPACE_SELECTION}-1])"
            Write-Host "Kubeconfig Path: ${global:KUBECONFIG_PATH}"

            # 네임스페이스 선택이 정상적으로 완료되면 다음단계 진행을 위해 "2" 을 리턴 -> 각 작업 함수의 ORDER변수에 3 할당되어 switch문 실행
            return 2
        }
    }
}

# 세부 작업 선택 후 네임스페이스 선택
function NamespaceSelect_Inner {
    while(1){

        # "네임스페이스 선택" 단계 알림 메시치 출력
        Write-Host "-------네임스페이스 선택-------" -BackgroundColor Yellow -ForegroundColor Red

        # 사용자가 잘못된 값 입력하여 while문 처음부터 수행할 때 변수 값을 0으로 초기화
        [int]$NAMESPACE_COUNT = 0

        # 사용자에게 선택 가능한 네임스페이스 출력
        foreach ($PARSING_NAMESPACE in ${NAMESPACE_LIST}) {
            $NAMESPACE_COUNT++
            Write-Host "${NAMESPACE_COUNT}: $PARSING_NAMESPACE"
        }

        Message_NoRefresh

        # 사용자의 네임스페이스 선택을 입력 받아 변수에 할당
        while(1){
            $NAMESPACE_SELECTION = Read-Host "Choose a namespace"
            if($NAMESPACE_SELECTION -ne '') {
                break
            }
        }

        # q를 입력할 경우 스크립트 종료
        if (${NAMESPACE_SELECTION} -eq "q") {
            Write-Host "Quit this script" -ForegroundColor Yellow
            exit 0
        }

        # b를 입력할 경우 이전 단계로 이동
        elseif (${NAMESPACE_SELECTION} -eq "b") {
            Write-Host "Return to the previous step" -ForegroundColor Yellow
            return 5
        }

        # f를 입력할 경우 이전 단계로 이동
        elseif (${NAMESPACE_SELECTION} -eq "f") {
            Write-Host "Return to the previous step" -ForegroundColor Yellow
            return 4
        }

        # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
        elseif (![int]::TryParse(${NAMESPACE_SELECTION}, [ref]$null) -or [int]${NAMESPACE_SELECTION} -lt 1 -or [int]${NAMESPACE_SELECTION} -gt $($NAMESPACE_LIST.Count) ) {
            Write-Host "Invalid selection. Please enter a number between 1 and $($NAMESPACE_LIST.Count)" -ForegroundColor Red
            continue
        }

        # 사용자가 유효한 값을 입력한 경우
        else{
            # 사용자가 유효한 값을 입력하면 선택한 네임스페이스를 $NAMESPACE 변수에 할당
            $global:NAMESPACE = $($NAMESPACE_LIST[${NAMESPACE_SELECTION}-1])
            Write-Host "Selected ${global:NAMESPACE}"

            # 네임스페이스 선택에 따라 Kubeconfig 파일 경로를 $KUBECONFIG_PATH에 변수로 설정
            $global:KUBECONFIG_PATH = "${KUBECONFIG}\$($KUBECONFIG_FILES[${NAMESPACE_SELECTION}-1])"
            Write-Host "Kubeconfig Path: ${global:KUBECONFIG_PATH}"

            # 네임스페이스 선택이 정상적으로 완료되면 다음단계 진행을 위해 "2" 을 리턴 -> 각 작업 함수의 ORDER변수에 3 할당되어 switch문 실행
            return 2
        }
    }
}

# 파드 선택
function PodSelect{

    # "파드 선택" 단계 알림 메시치 출력
    Write-Host "-------파드 선택-------" -BackgroundColor Yellow -ForegroundColor Red

    # 사용자가 잘못된 값 입력하여 while문 처음부터 수행할 때 변수 값을 0으로 초기화
	$PODS_COUNT = 0

    # 선택된 네임스페이스의 파드 목록을 리스트에 저장
    $global:PODS =(kubectl get pods -o=name --kubeconfig ${KUBECONFIG_PATH}).replace("pod/","")

    # 파드 목록 출력
    foreach ($POD in $global:PODS) {
        $PODS_COUNT++
        Write-Host "${PODS_COUNT}: $POD"
    }

    Message
    
    # 사용자의 파드 선택을 입력 받아 변수에 할당
    while(1){
        $global:POD_SELECTION = Read-Host "Choose a pod"
        if($global:POD_SELECTION -ne '') {
            break
        }
    }

    # 사용자가 q, b, f, r 을 입력하는 경우 
    if (${global:POD_SELECTION} -eq "q" -or ${global:POD_SELECTION} -eq "b" -or ${global:POD_SELECTION} -eq "f" -or ${global:POD_SELECTION} -eq "r") {
        return Check_Selection_b1_r2 -SELECTION ${global:POD_SELECTION}
    }

    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
    elseif (![int]::TryParse(${global:POD_SELECTION}, [ref]$null) -or [int]${global:POD_SELECTION} -lt 1 -or [int]${global:POD_SELECTION} -gt $($global:PODS.Count) ) {
        Write-Host "Invalid selection. Please enter a number between 1 and $($global:PODS.Count)" -ForegroundColor Red
        return 2
    }

    # 파드 선택이 정상적으로 완료되면 다음단계 진행을 위해 "3" 을 리턴 -> 각 작업 함수의 ORDER변수에 3 할당되어 switch문 실행
    return 3
}

# 인그레스 선택
function IngressSelect{
    
    # "인그레스 선택" 단계 알림 메시치 출력
    Write-Host "-------인그레스 선택-------" -BackgroundColor Yellow -ForegroundColor Red

    # 사용자가 잘못된 값 입력하여 while문 처음부터 수행할 때 변수 값을 0으로 초기화
	$INGRESS_COUNT = 0

    # 선택된 네임스페이스의 인그레스 목록을 리스트에 저장
    $global:INGRESSES=(kubectl get ingress -o=name --kubeconfig ${KUBECONFIG_PATH}).replace("ingress.networking.k8s.io/","")
    
	# 인그레스 목록 출력
    foreach ($INGRESS in $global:INGRESSES) {
        $INGRESS_COUNT++;
        Write-Host "${INGRESS_COUNT}: ${INGRESS}"
    }

    Message

    # 사용자의 파드 선택을 입력 받아 변수에 할당
    while(1){
        $global:INGRESS_SELECTION = Read-Host "Choose an ingress"
        if($global:INGRESS_SELECTION -ne '') {
            break
        }
    }

    # 사용자가 q, b, f, r 을 입력하는 경우 
    if (${global:INGRESS_SELECTION} -eq "q" -or ${global:INGRESS_SELECTION} -eq "b" -or ${global:INGRESS_SELECTION} -eq "f" -or ${global:INGRESS_SELECTION} -eq "r") {
        return Check_Selection_b1_r2 -SELECTION ${global:INGRESS_SELECTION}
    }

    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
    elseif (![int]::TryParse(${global:INGRESS_SELECTION}, [ref]$null) -or [int]${global:INGRESS_SELECTION} -lt 1 -or [int]${global:INGRESS_SELECTION} -gt $($global:INGRESSES.Count) ) {
        Write-Host "Invalid selection. Please enter a number between 1 and $($global:INGRESSES.Count)" -ForegroundColor Red
        return 2
    }

    # 인그레스 선택이 정상적으로 완료되면 다음단계 진행을 위해 "3" 을 리턴 -> 각 작업 함수의 ORDER변수에 3 할당되어 switch문 실행
    return 3
}

# 안내 메시지 출력
function Message{

    # q를 입력하면 스크립트가 종료된다는 메시지 출력
    Write-Host "Type " -NoNewline
    Write-Host "'q'" -NoNewline -ForegroundColor Magenta
    Write-Host " to quit this script"

    # b를 입력하면 이전 단계로 이동된다는 메시지 출력
    Write-Host "Type " -NoNewline
    Write-Host "'b'" -NoNewline -ForegroundColor Yellow
    Write-Host " to return to the previous step"

    # f를 입력하면 처음 단계로 이동된다는 메시지 출력
    Write-Host "Type " -NoNewline
    Write-Host "'f'" -NoNewline -ForegroundColor Red
    Write-Host " to return to the first step"

    # r를 입력하면 새로고침 된다는 메시지 출력
    Write-Host "Type " -NoNewline
    Write-Host "'r'" -NoNewline -ForegroundColor Green
    Write-Host " to refresh this step"
    return
}

# Refresh 기능이 필요 없을 때 안내 메시지 출력
function Message_NoRefresh{

    # q를 입력하면 스크립트가 종료된다는 메시지 출력
    Write-Host "Type " -NoNewline
    Write-Host "'q'" -NoNewline -ForegroundColor Magenta
    Write-Host " to quit this script"

    # b를 입력하면 이전 단계로 이동된다는 메시지 출력
    Write-Host "Type " -NoNewline
    Write-Host "'b'" -NoNewline -ForegroundColor Yellow
    Write-Host " to return to the previous step"

    # f를 입력하면 처음 단계로 이동된다는 메시지 출력
    Write-Host "Type " -NoNewline
    Write-Host "'f'" -NoNewline -ForegroundColor Red
    Write-Host " to return to the first step"
    return
}

# Quit 과 Back 기능만 필요할 때
function Message_Quit_Back{

    # q를 입력하면 스크립트가 종료된다는 메시지 출력
    Write-Host "Type " -NoNewline
    Write-Host "'q'" -NoNewline -ForegroundColor Magenta
    Write-Host " to quit this script"

    # b를 입력하면 이전 단계로 이동된다는 메시지 출력
    Write-Host "Type " -NoNewline
    Write-Host "'b'" -NoNewline -ForegroundColor Yellow
    Write-Host " to return to the previous step"
    return
}

# Back은 Order 변수 값이 2이고 Refresh는 Order 변수 값이 3인 경우
function Check_Selection_b2_r3{
    
    # 사용자의 입력을 파라미터로 받아옴
    param (
        $SELECTION
    )

    # q를 입력할 경우 스크립트 종료
    if (${SELECTION} -eq "q") {
        Write-Host "Quit this script" -ForegroundColor Yellow
        exit 0
    }

    # f를 입력할 경우 처음 단계로 이동
    elseif (${SELECTION} -eq "f"){
        Write-Host "Return to the first step" -ForegroundColor Yellow
        $ORDER = 4
    }

    # b를 입력할 경우 이전 단계로 이동
    elseif (${SELECTION} -eq "b") {
        Write-Host "Return to the previous step" -ForegroundColor Yellow
        $ORDER = 2
    }
                    
    # r을 입력할 경우 새로고침 수행
    elseif (${SELECTION} -eq "r") {
        Write-Host "Refresh this step" -ForegroundColor Yellow
        $ORDER = 3
    }
    
    # ORDER 값을 전달하여 다음 단계 수행
    return $ORDER
}

# Back은 Order 변수 값이 1이고 Refresh는 Order 변수 값이 2인 경우
function Check_Selection_b1_r2{

    # 사용자의 입력을 파라미터로 받아옴
    param (
        $SELECTION
    )

    # q를 입력할 경우 스크립트 종료
    if (${SELECTION} -eq "q") {
        Write-Host "Quit this script" -ForegroundColor Yellow
        exit 0
    }

    # f를 입력할 경우 처음 단계로 이동
    elseif (${SELECTION} -eq "f"){
        Write-Host "Return to the first step" -ForegroundColor Yellow
        $ORDER = 4
    }

    # b를 입력할 경우 이전 단계로 이동
    elseif (${SELECTION} -eq "b") {
        Write-Host "Return to the previous step" -ForegroundColor Yellow
        $ORDER = 1
    }
                    
    # r을 입력할 경우 새로고침 수행
    elseif (${SELECTION} -eq "r") {
        Write-Host "Refresh this step" -ForegroundColor Yellow
        $ORDER = 2
    }

    # ORDER 값을 전달하여 다음 단계 수행
    return $ORDER
}

# Back은 Order 변수 값이 3이고 Refresh 기능은 필요 없는 경우
function Check_Selection_b3_rNo{
    
    # 사용자의 입력을 파라미터로 받아옴
    param (
        $SELECTION
    )

    # q를 입력할 경우 스크립트 종료
    if (${SELECTION} -eq "q") {
        Write-Host "Quit this script" -ForegroundColor Yellow
        exit 0
    }

    # f를 입력할 경우 처음 단계로 이동
    elseif (${SELECTION} -eq "f"){
        Write-Host "Return to the first step" -ForegroundColor Yellow
        $ORDER = 4
    }

    # b를 입력할 경우 이전 단계로 이동
    elseif (${SELECTION} -eq "b") {
        Write-Host "Return to the previous step" -ForegroundColor Yellow
        $ORDER = 3
    }
    
    # ORDER 값을 전달하여 다음 단계 수행
    return $ORDER
}

# 4 Jeus Admin 작업 선택
function Number0_4 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect
                continue
            }

            # 파드 선택
            2 {
                $ORDER = PodSelect
                continue
            }
            # JEUS_ADMIN 작업 선택
            3 {

                # "Jeus Admin 명령어 모음" 단계 알림 메시치 출력
                Write-Host "-------Jeus Admin 명령어 모음 작업 선택-------" -BackgroundColor Yellow -ForegroundColor Red

                # 사용자에게 작업 목록 출력
                foreach ($CHOICE in $CHOICES_JEUS_ADMIN.GetEnumerator()) {
                Write-Host "$($CHOICE.Key) $($CHOICE.Value)"
                }

                # 스크립트 단계 이동 조건 출력
                Message_NoRefresh

                # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                while(1){
                    $JOB = Read-Host "Choose a container"
                    if($JOB -ne '') {
                        break
                    }
                }

                # 사용자 선택 값을 확인
                if (${JOB} -eq "q" -or ${JOB} -eq "f" -or ${JOB} -eq "b"){
                    $ORDER = Check_Selection_b2_r3 -Selection ${JOB}
                    continue
                }

                # 사용자가 유효하지 않은 값을 입력할 경우 안내 메시지 출력 후 SelectJob 다시 실행
                elseif (![int]::TryParse($JOB, [ref]$null) -or [int]${JOB} -lt 1 -or [int]${JOB} -gt $($CHOICES_JEUS_ADMIN.Count) ) {
                    Write-Host "Invalid selection. Please enter a number between 1 and $($CHOICES_JEUS_ADMIN.Count)" -ForegroundColor Red
                    continue
                }

                # Jeusadmin 접속
                elseif($JOB -eq 1){
                    $ORDER = 6
                    continue
                }

                # Jeus Corelated server 목록 조회
                elseif($JOB -eq 2){
                    $ORDER = 7
                    continue
                }

                # Jeus 백업 서버 목록 확인
                elseif($JOB -eq 3){
                    $ORDER = 8
                    continue
                }

                # Server information 조회
                elseif($JOB -eq 4){
                    $ORDER = 9
                    continue
                }

                # list-servers 확인
                elseif($JOB -eq 5){
                    $ORDER = 10
                    continue
                }
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return
            }

            # 뒤로가기 수행
            5{
                return 4
            }

            # JEUS_ADMIN 접속
            6 {

                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){

                    try {
                        # JEUS Admin 접속 포트 변수 할당
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # 안내 메시지 출력
                        Write-Host -NoNewline "Access to jeusadmin of "
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green
                        
                        # 선택된 파드에서 jeusadmin 접속          
                        Start-Process -NoNewWindow -Wait -FilePath 'kubectl' -ArgumentList "exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c `"/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT}`""

                        # 종료 안내 메시지 출력
                        Write-Host "`nTerminating session..."
                    }
                    catch {
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 파드" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # 작업 완료 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 3
                    continue
                }

                # 파드내 컨테이너가 2개 이상일 경우
                else {
                    
                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message_NoRefresh

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break 
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b"){
                        $ORDER = Check_Selection_b3_rNo -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    try {
                        # JEUS Admin 접속 포트 변수 할당
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # 안내 메시지 출력
                        Write-Host -NoNewline "Access to jeusadmin of "
                        Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green
                        
                        # 선택된 파드에서 jeusadmin 접속
                        Start-Process -NoNewWindow -Wait -FilePath 'kubectl' -ArgumentList "exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c `"/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT}`""
                        # kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT}" | Out-Host 

                        # 종료 안내 메시지 출력
                        Write-Host "Terminating session..."
                    }
                    catch {
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 컨테이너" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }
                    
                    # 작업 완료 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 3
                    continue
                }
            }

            # Jeus Corelated server 목록 조회
            7 {

                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){

                    try {
                        # JEUS Admin 접속 포트 변수 할당
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # 안내 메시지 출력
                        Write-Host -NoNewline "Checking list of corelated-servers of "
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                        # 선택된 파드에서 list-corelated-servers 확인
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'list-corelated-servers'" | Out-Host
                        
                        # 종료 안내 메시지 출력
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 파드" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # 작업 완료 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 3
                    continue
                }
                else {
                    
                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message_NoRefresh

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b"){
                        $ORDER = Check_Selection_b3_rNo -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                    
                    try {
                        # JEUS Admin 접속 포트 변수 할당
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # 안내 메시지 출력
                        Write-Host -NoNewline "Checking list of corelated-servers of "
                        Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green
                        
                        # 선택된 파드에서 list-corelated-servers 확인
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'list-corelated-servers'" | Out-Host
                        
                        # 종료 안내 메시지 출력
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 컨테이너" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # 작업 완료 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 3
                    continue
                }
            }

            # Jeus 백업 서버 목록 확인
            8 {

                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){

                    try {
                        # JEUS Admin 접속 포트 변수 할당
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # 안내 메시지 출력
                        Write-Host -NoNewline "Checking list of show-web-statistics of "
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                        # 선택된 파드에서 Jeus 백업 서버 목록 확인
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'show-web-statistics -server $($PODS[$POD_SELECTION-1])'" | Out-Default
                        
                        # 종료 안내 메시지 출력
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 파드" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # 작업 완료 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 3
                    continue
                }
                else {
                    
                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message_NoRefresh

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b"){
                        $ORDER = Check_Selection_b3_rNo -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                    
                    try {
                        # JEUS Admin 접속 포트 변수 할당
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # 안내 메시지 출력
                        Write-Host -NoNewline "Checking list of show-web-statistics of of "
                        Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green
                        
                        # 선택된 파드에서 Jeus 백업 서버 목록 확인
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'show-web-statistics -server $($PODS[$POD_SELECTION-1])'" | Out-Default
                        
                        # 종료 안내 메시지 출력
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 컨테이너" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # 작업 완료 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 3
                    continue
                }
            }

            # Server information 조회
            9 {

                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){

                    try {
                        # JEUS Admin 접속 포트 변수 할당
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # 안내 메시지 출력
                        Write-Host -NoNewline "Checking Server information of "
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                        # 선택된 파드에서 Server information 확인
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'si'" | Out-Default
                        
                        # 종료 안내 메시지 출력
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 파드" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # 작업 완료 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 3
                    continue
                }
                else {
                    
                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message_NoRefresh

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b"){
                        $ORDER = Check_Selection_b3_rNo -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                    
                    try {
                        # JEUS Admin 접속 포트 변수 할당
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # 안내 메시지 출력
                        Write-Host -NoNewline "Checking Server information of "
                        Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green
                        
                        # 선택된 파드에서 Server information 확인
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'si'" | Out-Default
                        
                        # 종료 안내 메시지 출력
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 컨테이너" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # 작업 완료 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 3
                    continue
                }
            }

            # list-servers 조회
            10 {

                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){

                    try {
                        # JEUS Admin 접속 포트 변수 할당
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # 안내 메시지 출력
                        Write-Host -NoNewline "Checking list-servers of "
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                        # 선택된 파드에서 list-servers 확인
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'list-servers'" | Out-Default
                        
                        # 종료 안내 메시지 출력
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 파드" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # 작업 완료 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 3
                    continue
                }
                else {
                    
                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message_NoRefresh

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b"){
                        $ORDER = Check_Selection_b3_rNo -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                    
                    try {
                        # JEUS Admin 접속 포트 변수 할당
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # 안내 메시지 출력
                        Write-Host -NoNewline "Checking list-servers of "
                        Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green
                        
                        # 선택된 파드에서 list-servers 확인
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'list-servers'" | Out-Default
                        
                        # 종료 안내 메시지 출력
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 컨테이너" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # 작업 완료 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 3
                    continue
                }
            }
        }        
    }
}

# 0-5. 파드 쉘 접속
function Number0_5 {
    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect
                continue
            }

            # 파드 선택
            2 {
                $ORDER = PodSelect
                continue
            }

            # 컨테이너 선택 & 작업
            3 {
                
                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){

                    # 파드 연결 메시지 출력
                    Write-Host -NoNewline "Connect to "
                    Write-Host "$($PODS[$POD_SELECTION-1])e" -ForegroundColor Green

                    # 선택된 파드/컨테이너 접속
                    try{
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- /bin/bash 2> $null
                        if($LASTEXITCODE -eq 1){
                            throw "error 발생"
                        }
                    }
                    catch{
                        Write-Host "선택된 파드가 이미 제거되었거나 클러스터에 api요청을 보낼 수 없습니다. 적절한 조치 후 시도해주세요."
                    }
		            
                    # 파드 접속 종료 후 파드 선택 단계부터 재실행
                    $ORDER = 2
                    continue
                }
                else {
                    
                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red

                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }
                    
                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # 파드 연결 메시지 출력
                    Write-Host -NoNewline "Connect to "
                    Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor Green

                    # 선택된 파드/컨테이너 접속
                    try{
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- /bin/bash 2> $null
                        if($LASTEXITCODE -eq 1){
                            throw "error 발생"
                        }
                    }
                    catch{
                        Write-Host "선택된 파드가 이미 제거되었거나 클러스터에 api요청을 보낼 수 없습니다. 적절한 조치 후 다시 시도해주세요."
                    }
                    
                    # 파드 접속 종료 후 파드 선택 단계부터 재실행
                    $ORDER = 2
                    continue
                }
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return
            }
        }        
    }
}

# 0-6. Network Policy 자동 생성(SKE 개발자 가이드)
function Number0_6 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch (${ORDER}) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect
                continue
            }

            # 네트워크 폴리시 생성
            2 {
                # 임시파일 생성 시 중복 생성을 피하기 위해 시간을 변수에 할당하여 해당 값을 파일 이름애 붙여 사용
                $TIME = Get-Date -Format "yyyy/MM/dd"

                # "Network Policy 생성 중" 메시지 출력
                Write-Host "Creating Network Policies." -NoNewline -ForegroundColor Yellow
                Write-Host "..."

                # Ingress Controller의 Name을 변수로 설정
                $INGRESS_CONTROLLERS = (kubectl get deployment -o name --kubeconfig ${KUBECONFIG_PATH} -l app=ingress-controller).replace("deployment.apps/","")
                
                # Release Name을 변수로 설정 -> 여러개의 Ingress Controller 가 존재할 경우 여러개의 NetworkPolicy 생성이 필요하기 때문
                $RELEASES = @()
                foreach($INGRESS_CONTROLLER in $INGRESS_CONTROLLERS) {
                    $TEMP = kubectl get deployment ${INGRESS_CONTROLLER} --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.metadata.labels.release}"
                    $RELEASES += $TEMP
                }

                # Network Policy 생성을 위한 임시 YAML파일 생성
                $NETWORKPOLICY_YAML = @"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: ${NAMESPACE}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-kube-system-namespace
  namespace: ${NAMESPACE}
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/namespace: kube-system
  podSelector: {}
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-namespace-traffic
  namespace: ${NAMESPACE}
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ${NAMESPACE}
  podSelector: {}
  policyTypes:
  - Ingress
"@
                # 임시파일 생성 후 Manifest 내용 추가
                Set-Content -Path "./networkpolicy_temp_${TIME}.yaml" -Value $NETWORKPOLICY_YAML

                # 여러개의 Ingress Controller 가 존재할 경우 여러개의 NetworkPolicy 생성하기 위해 foreach문 사용
                foreach($RELEASE in $RELEASES) {
                    $SERVICE_NAME = ''
                    if($RELEASE.contains("nginx-")){
                        $SERVICE_NAME = $RELEASE.replace("nginx-","")
                    }
                    else{
                        $SERVICE_NAME = $RELEASE
                    }
                    $NETWORKPOLICY_INGRESS_YAML = @"
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingresscontroller-traffic-${SERVICE_NAME}
  namespace: ${NAMESPACE}
spec:
  ingress:
  - ports:
    - port: 80 
      protocol: TCP
    - port: 443
      protocol: TCP
  podSelector:
    matchLabels:
      app: ingress-controller
      app.kubernetes.io/component: controller
      app.kubernetes.io/instance: ${RELEASE}
      app.kubernetes.io/name: ingress-controller
      release: ${RELEASE}
  policyTypes:
  - Ingress
"@
                    # Manifest 내용 임시파일에 추가
                    Add-Content -Path "./networkpolicy_temp_${TIME}.yaml" -Value $NETWORKPOLICY_INGRESS_YAML
                }

                # 사용자에게 생성될 Network policy manifest 출력
                kubectl apply --kubeconfig=${KUBECONFIG_PATH} --dry-run=client -o yaml -f ./networkpolicy_temp_${TIME}.yaml

                # "실제 생성 선택" 단계 알림 메시치 출력
                Write-Host "-------실행 선택 입력-------" -BackgroundColor Yellow -ForegroundColor Red

                # Network policy 생성하기 전 사용자에게 확인 응답 요청
                Write-Host "Please confirm the YAML`nAre you sure to create network policies?(Y/N)" -ForegroundColor Yellow

                # 실제 생성할 것인지 사용자에게 입력을 응답 받음
                while(1) {
                    $SELECT = Read-Host " "
                    # N을 입력할 경우 실제 생성하지 않음
                    if($SELECT -eq 'N'){
                        break
                    }
                    # Y를 입력할 경우 실제로 네트워크 폴리시 생성
                    elseif($SELECT -eq 'Y') {
                        kubectl apply --kubeconfig=${KUBECONFIG_PATH} -f ./networkpolicy_temp_${TIME}.yaml
                        break
                    }
                    # 공백을 입력하면 다시 입력 받도록 함
                    elseif($SELECT -eq '') {
                        continue
                    }
                    # 잘못된 값을 입력할 경우 알림 메시지 출력 후 다시 입력 받음
                    else {
                        Write-Host "Please enter correct value(Y/N)" -ForegroundColor Red
                        continue
                    }
                }

                # 임시파일 제거
                Remove-Item ./networkpolicy_temp_${TIME}.yaml

                # Network Policy 생성 완료 후 네임스페이스 선택 단계로 돌아가기 위해 ORDER변수에 1를 할당 후 continue 수행
                $ORDER = 1
                continue
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return
            }
        }        
    }
}

# 0-7. 파일 복사 (컨테이너 <-> 로컬 PC)
function Number0_7 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect
                continue
            }

            # 파드 선택
            2 {
                $ORDER = PodSelect
                continue
            }

            # 컨테이너 선택 & 작업
            3 {

                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){
                    
                    # "복사 옵션 선택" 단계 알림 메시치 출력
                    Write-Host "-------복사 옵션 선택-------" -BackgroundColor Yellow -ForegroundColor Red

                    # 복사 옵션 선택 (Cotainer to Local PC / Local PC to Container)
                    Write-Host "Select Copy Option`n1: Container to local`n2: Local to container"

                    Message_NoRefresh

                    # 사용자의 선택을 입력 받음
                    while(1){
                        $COPY_OPTION = Read-Host "Choose an option"
                        if($COPY_OPTION -ne ''){
                            break
                        }
                    }

                    # q를 입력할 경우 스크립트 종료
                    if (${COPY_OPTION} -eq "q" -or ${COPY_OPTION} -eq "f" -or ${COPY_OPTION} -eq "b") {
                        $ORDER = Check_Selection_b2_r3 -SELECTION ${COPY_OPTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${COPY_OPTION}, [ref]$null) -or [int]${COPY_OPTION} -lt 1 -or [int]${COPY_OPTION} -gt 2 ) {
                        Write-Host "Invalid selection. Please enter a number 1 or 2" -ForegroundColor Red
                        continue
                    }

                    # Cotainer to Local PC
                    elseif( $COPY_OPTION -eq 1 ) {
                        
                        # "소스파일 경로(컨테이너) 입력" 단계 알림 메시치 출력
                        Write-Host "-------소스파일 경로(컨테이너) 입력-------" -BackgroundColor Yellow -ForegroundColor Red

                        # 소스파일 경로(컨테이너) 설정
                        While(1){
                            $SRC = Read-Host "Type path of source file."
                            if($SRC -ne '') {
                                break
                            }
                        }
                        $SOURCE = $($PODS[$POD_SELECTION-1])+":"+ ${SRC}

                        # "저장 경로(로컬) 입력" 단계 알림 메시치 출력
                        Write-Host "-------저장 경로(로컬) 입력-------" -BackgroundColor Yellow -ForegroundColor Red

                        # 저장 경로(로컬) 설정
                        While(1){
                            $DESTINATION = Read-Host "Type path of destination file."
                            if($DESTINATION -ne ''){
                                break
                            }
                        }

                        # 로그 저장
                        kubectl cp ${SOURCE} ${DESTINATION} --kubeconfig ${KUBECONFIG_PATH}
                    }

                    # Local PC to Container
                    elseif($COPY_OPTION -eq 2) {

                        # "소스파일 경로(로컬) 입력" 단계 알림 메시치 출력
                        Write-Host "-------소스파일 경로(컨테이너) 입력-------" -BackgroundColor Yellow -ForegroundColor Red

                        # 소스파일 경로(로컬) 설정
                        While(1){
                            $SOURCE = Read-Host "Type path of source file."
                            if($SOURCE -ne ''){
                                break
                            }
                        }
                        
                        # "저장 경로(컨테이너) 입력" 단계 알림 메시치 출력
                        Write-Host "-------저장 경로(컨테이너) 입력-------" -BackgroundColor Yellow -ForegroundColor Red

                        # 저장 경로(컨테이너) 설정
                        While(1){
                            $DEST = Read-Host "Type path of destination file."
                            if($DEST -ne ''){
                                break
                            }
                        }
                        $DESTINATION = $($PODS[$POD_SELECTION-1])+":"+ ${DEST}

                        # 로그 저장
                        kubectl cp ${SOURCE} ${DESTINATION} --kubeconfig ${KUBECONFIG_PATH}
                    }

                    # 로그 저장 완료 후 ORDER 변수에 2를 할당하여 파드 선택 부터 다시 실행
                    $ORDER = 2
                    continue
                }

                # 컨테이너가 2개 이상일 경우
                else {
                    
                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0
                    
                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                    
                    # "복사 옵션 선택" 단계 알림 메시치 출력
                    Write-Host "-------복사 옵션 선택-------" -BackgroundColor Yellow -ForegroundColor Red

                    # 복사 옵션 선택 (Cotainer to Local PC / Local PC to Container)
                    Write-Host "Select Copy Option`n1.Container to local`n2.Local to container"

                    Message_NoRefresh
                    
                    # 사용자의 입력을 변수에 할당
                    While(1){
                        $COPY_OPTION = Read-Host "Choose an option"
                        if($COPY_OPTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${COPY_OPTION} -eq "q" -or ${COPY_OPTION} -eq "f" -or ${COPY_OPTION} -eq "b"){
                        $ORDER = Check_Selection_b3_rNo -Selection ${COPY_OPTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${COPY_OPTION}, [ref]$null) -or [int]${COPY_OPTION} -lt 1 -or [int]${COPY_OPTION} -gt 2 ) {
                        Write-Host "Invalid selection. Please enter a number 1 or 2" -ForegroundColor Red
                        continue
                    }
                    

                    # Cotainer to Local PC
                    elseif( $COPY_OPTION -eq 1 ) {
                        
                        # "소스파일 경로(컨테이너) 입력" 단계 알림 메시치 출력
                        Write-Host "-------소스파일 경로(컨테이너) 입력-------" -BackgroundColor Yellow -ForegroundColor Red

                        # 소스파일 경로(컨테이너) 설정
                        while(1){
                            $SRC = Read-Host "Type path of source file."
                            if($SRC -ne '') {
                                break
                            }
                        }
                        $SOURCE = $($PODS[$POD_SELECTION-1])+":"+ ${SRC}
                        
                        # "저장 경로(로컬) 입력" 단계 알림 메시치 출력
                        Write-Host "-------저장 경로(로컬) 입력-------" -BackgroundColor Yellow -ForegroundColor Red
                        
                        # 저장 경로(로컬) 설정
                        while(1){
                            $DESTINATION = Read-Host "Type path of destination file."
                            if($DESTINATION -ne '') {
                                break
                            }
                        }
                        # 로그 저장
                        kubectl cp -c $($CONTAINERS[$CONTAINER_SELECTION-1]) ${SOURCE} ${DESTINATION} --kubeconfig ${KUBECONFIG_PATH}
                    }

                    # Local PC to Container
                    elseif($COPY_OPTION -eq 2) {
                        
                        # "소스파일 경로(로컬) 입력" 단계 알림 메시치 출력
                        Write-Host "-------소스파일 경로(로컬) 입력-------" -BackgroundColor Yellow -ForegroundColor Red
                        
                        # 소스파일 경로(로컬) 설정
                        while(1) {
                            $SOURCE = Read-Host "Type path of source file."
                            if($SOURCE -ne ''){
                                break
                            }
                        }
                                                
                        # "저장 경로(컨테이너) 입력" 단계 알림 메시치 출력
                        Write-Host "-------저장 경로(컨테이너) 입력-------" -BackgroundColor Yellow -ForegroundColor Red

                        # 저장 경로(컨테이너) 설정
                        while(1){
                            $DEST = Read-Host "Type path of destination file."
                            if($DEST -ne ''){
                                break
                            }
                        }
                        $DESTINATION = $($PODS[$POD_SELECTION-1])+":"+ ${DEST}

                        # 로그 저장
                        kubectl cp -c $($CONTAINERS[$CONTAINER_SELECTION-1]) ${SOURCE} ${DESTINATION} --kubeconfig ${KUBECONFIG_PATH}
                    }

                    # 로그 저장 완료 후 ORDER 변수에 2를 할당하여 파드 선택 부터 다시 실행
                    $ORDER = 2
                    continue
                }
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return
            }

        }        
    }
}

# 0-8. DB 커넥션 테스트
function Number0_8 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect
                continue
            }

            # 파드 선택
            2 {''
                $ORDER = PodSelect
                continue
            }

            # 컨테이너 선택 & 작업
            3 {

                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){
                    
                    # "DB IP 입력" 단계 알림 메시치 출력
                    Write-Host "-------DB IP 입력-------" -BackgroundColor Yellow -ForegroundColor Red

                    # 사용자에게 DB IP 를 입력 받아 변수에 할당
                    while(1){
                        $DB_IP = Read-Host "Type DB IP: "
                        if($DB_IP -ne ''){
                            break
                        }
                    }

                    # "DB Port 입력" 단계 알림 메시치 출력
                    Write-Host "-------DB Port 입력-------" -BackgroundColor Yellow -ForegroundColor Red

                    # 사용자에게 DB Port 를 입력 받아 변수에 할당
                    while(1){
                        $DB_PORT = Read-Host "Type DB Port: "
                        if ($DB_PORT -ne ''){
                            break
                        }
                    }
                    

                    # 연결 테스트 중이라는 메시지 출력
                    Write-Host -NoNewline "Connecting test from "
                    Write-Host "$($PODS[$POD_SELECTION-1]) to ${DB_IP}:${DB_PORT}" -ForegroundColor green

                    # 선택된 파드에서 DB Connection Test 진행
		            kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- curl -v telnet://${DB_IP}:${DB_PORT}

                    # 커넥션 테스트 완료 후 ORDER 변수에 2를 할당하여 파드 선택 부터 다시 실행
                    $ORDER = 2
                    continue
                }

                # 컨테이너가 2개 이상일 경우
                else {
                                        
                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # "DB IP 입력" 단계 알림 메시치 출력
                    Write-Host "-------DB IP 입력-------" -BackgroundColor Yellow -ForegroundColor Red

                    # 사용자에게 DB IP 를 입력 받아 변수에 할당우
                    while(1){
                        $DB_IP = Read-Host "Type DB IP: "
                        if($DB_IP -ne ''){
                            break
                        }
                    }

                    # "DB Port 입력" 단계 알림 메시치 출력
                    Write-Host "-------DB Port 입력-------" -BackgroundColor Yellow -ForegroundColor Red

                    # 사용자에게 DB Port 를 입력 받아 변수에 할당
                    While(1) {
                        $DB_PORT = Read-Host "Type DB Port: "
                        if($DB_PORT -ne ''){
                            break
                        }
                    }
                    # 연결 테스트 중이라는 메시지 출력
                    Write-Host -NoNewline "Connecting test from "
                    Write-Host "$($PODS[$POD_SELECTION-1])/$($CONTAINERS[$CONTAINER_SELECTION-1]) to ${DB_IP}:${DB_PORT}" -ForegroundColor green
                    
                    # 선택된 파드에서 DB Connection Test 진행
		            kubectl exec -it -c $($CONTAINERS[$CONTAINER_SELECTION-1]) $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- curl -v telnet://${DB_IP}:${DB_PORT}

                    # 커넥션 테스트 완료 후 ORDER 변수에 2를 할당하여 파드 선택 부터 다시 실행
                    $ORDER = 2
                    continue
                    
                }
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return
            }

        }        
    }
}

# 1-1 모든 네임스페이스의 POD CPU/Memory 점유 상태 조회
function Number1_1 {

    # sum, --containers 옵션 있는 경우
    try {

        # Kubectl top에 --sum, --containers 옵션이 포함되어 있는지 확인한다는 메시지 출력
        Write-Host "Checking 'Kubectl top' includes " -NoNewline; Write-Host "'--sum'" -NoNewline -ForegroundColor Green; Write-Host " and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Green; Write-Host " options...";
        
        # Kubectl 버전에 따라 옵션이 없는 경우에 예외 발생시키기 위한 로직
        kubectl top pods --kubeconfig $KUBECONFIG\$($KUBECONFIG_FILES[0]) --containers --sum > $null 2>&1
        if ($LASTEXITCODE) {
            throw "$LASTEXITCODE"
        }

        # kubectl top에 --sum과 --containers 옵션이 포함되어 있다는 메시지 출력
        Write-Host "Kubectl top includes " -NoNewline; Write-Host "'--sum' " -NoNewline -ForegroundColor Green; Write-Host "and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Green; Write-Host " options";

        # 작업 완료 후 다음 실행을 위해 변수 초기화
        [int]$COUNT = 0

        # POD CPU/Memory 점유 상태 조회
        foreach ($KUBECONIFG_FILE in $KUBECONFIG_FILES) {
            Write-Host -NoNewline "------------------------------------------------"
            Write-Host -NoNewline "$(${NAMESPACE_LIST}[$COUNT++])".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue
            Write-Host "------------------------------------------------"
            kubectl top pods --kubeconfig $KUBECONFIG\$KUBECONIFG_FILE --containers --sum

        }
    }

    # sum, --containers 옵션 없는 경우
    catch{
        
        # kubectl top에 --sum과 --containers 옵션이 포함되어 있지 않다는 메시지 출력
        Write-Host "'--sum' " -NoNewline -ForegroundColor Red; Write-Host "and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Red; Write-Host " options does not exist";

        # 작업 완료 후 다음 실행을 위해 변수 초기화
        [int]$COUNT = 0
        
        # POD CPU/Memory 점유 상태 조회
        foreach ($KUBECONIFG_FILE in $KUBECONFIG_FILES) {
            Write-Host -NoNewline "------------------------------------------------"
            Write-Host -NoNewline "$(${NAMESPACE_LIST}[$COUNT++])".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue
            Write-Host "------------------------------------------------"
            kubectl top pods --kubeconfig $KUBECONFIG\$KUBECONIFG_FILE
        }
    }
}

# 1-2 특정 네임스페이스의 Pod CPU/Memory 점유 상태 조회
function Number1_2 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # CPU/Memory 상태 조회
            2 {

                # sum, --containers 옵션 있는 경우
                try {
                    
                    # Kubectl top에 --sum, --containers 옵션이 포함되어 있는지 확인한다는 메시지 출력
                    Write-Host "Checking 'Kubectl top' includes " -NoNewline; Write-Host "'--sum'" -NoNewline -ForegroundColor Green; Write-Host " and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Green; Write-Host " options...";
                    
                    # Kubectl 버전에 따라 옵션이 없는 경우에 예외 발생시키기 위한 로직
                    kubectl top pods --kubeconfig $KUBECONFIG\$($KUBECONFIG_FILES[0]) --containers --sum > $null 2>&1
                    if ($LASTEXITCODE) {
                        throw "$LASTEXITCODE"
                    }

                    # kubectl top에 --sum과 --containers 옵션이 포함되어 있다는 메시지 출력
                    Write-Host "Kubectl top includes " -NoNewline; Write-Host "'--sum' " -NoNewline -ForegroundColor Green; Write-Host "and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Green; Write-Host " options";

                    # 선택한 네임스페이스에 대해 출력
                    Write-Host -NoNewline "------------------------------------------------"; Write-Host -NoNewline "$NAMESPACE".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue; Write-Host "------------------------------------------------";
                    kubectl top pods --kubeconfig ${KUBECONFIG_PATH} --containers --sum | Out-Host
                    Write-Host "------------------------------------------------------------------------------------------------" -NoNewline; Write-Host ("-" * ($NAMESPACE).Length);

                    # 출력 완료 후 네임스페이스 선택으로 돌아가기 위해 $ORDER에 1을 할당하고 while문 다시 수행
                    $ORDER = 1
                    continue
                }

                # sum, --containers 옵션 없는 경우
                catch{
                    
                    # kubectl top에 --sum과 --containers 옵션이 포함되어 있지 않다는 메시지 출력
                    Write-Host "'--sum' " -NoNewline -ForegroundColor Red; Write-Host "and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Red; Write-Host " options does not exist";

                    # 선택한 네임스페이스에 대해 출력
                    Write-Host -NoNewline "------------------------------------------------"; Write-Host -NoNewline "$NAMESPACE".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue; Write-Host "------------------------------------------------";
                    kubectl top pods --kubeconfig ${KUBECONFIG_PATH} | Out-Host
                    Write-Host "------------------------------------------------------------------------------------------------" -NoNewline; Write-Host ("-" * ($NAMESPACE).Length);

                    # 출력 완료 후 네임스페이스 선택으로 돌아가기 위해 $ORDER에 1을 할당하고 while문 다시 수행
                    $ORDER = 1
                    continue
                }
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return 0
            }

            # 뒤로가기 수행
            5{
                return 1
            }

        }        
    }
}

# 1-3 CPU, Memory 실시간 모니터링
function Number1_3 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # CPU/Memory 상태 조회
            2 {

                # sum, --containers 옵션 있는 경우
                try {
                    
                    # Kubectl top에 --sum, --containers 옵션이 포함되어 있는지 확인한다는 메시지 출력
                    Write-Host "Checking 'Kubectl top' includes " -NoNewline; Write-Host "'--sum'" -NoNewline -ForegroundColor Green; Write-Host " and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Green; Write-Host " options...";
                    
                    # Kubectl 버전에 따라 옵션이 없는 경우에 예외 발생시키기 위한 로직
                    kubectl top pods --kubeconfig $KUBECONFIG\$($KUBECONFIG_FILES[0]) --containers --sum --use-protocol-buffers=true > $null 2>&1
                    if ($LASTEXITCODE) {
                        throw "$LASTEXITCODE"
                    }

                    # kubectl top에 --sum과 --containers 옵션이 포함되어 있다는 메시지 출력
                    Write-Host "Kubectl top includes " -NoNewline; Write-Host "'--sum' " -NoNewline -ForegroundColor Green; Write-Host "and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Green; Write-Host " options";

                    # 호스트 출력을 지움 -> 커서 위치가 최상단으로 변경됨
                    Clear-Host

                    # 현재 커서 위치(최상단)를 변수에 지정
                    $CURRENTCURSORPOSITION = $Host.UI.RawUI.CursorPosition

                    # 선택한 네임스페이스에 대해 출력
                    while(1){

                        $DATE = (Get-Date -Format 'yyyy-MM-dd HH:mm.ss.fff')
                        
                        # kubectl 결과값을 변수에 할당
                        $RESULT = $(kubectl top pods --kubeconfig ${KUBECONFIG_PATH} --containers --sum --use-protocol-buffers=true)

                        # 현재 커서 위치(최상단) 변수를 최상단으로 변경
                        $Host.UI.RawUI.CursorPosition = $CURRENTCURSORPOSITION
                        
                        # 결과값 출력                        
                        Write-Host "${DATE}"
                        Write-Host -NoNewline "------------------------------------------------"; Write-Host -NoNewline "$NAMESPACE".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue; Write-Host "------------------------------------------------";
                        $RESULT -split '\r?\n' | ForEach-Object { Write-Host "$_" }
                        Write-Host "------------------------------------------------------------------------------------------------" -NoNewline; Write-Host ("-" * ($NAMESPACE).Length);

                        # 사용자 입력에 따른 안내문 출력
                        Write-Host "Press " -NoNewline; Write-Host "'q'" -NoNewline -ForegroundColor Yellow; Write-Host " to quit this step.";
                        Write-Host "Press " -NoNewline; Write-Host "'c'" -NoNewline -ForegroundColor Yellow; Write-Host " to clear this terminal." -NoNewline;

                        # 사용자가 입력에 따라 다음을 수행
                        if ([System.Console]::KeyAvailable) {
                            $KEY = [System.Console]::ReadKey($true)

                            # q를 입력하면 while문 종료
                            if ($KEY.KeyChar -eq 'q' -or $KEY.KeyChar -eq 'Q') {
                                Write-Host "`nQuit this step"
                                break
                            }

                            # c를 입력하면 clear 수행
                            elseif ($KEY.KeyChar -eq 'c' -or $KEY.KeyChar -eq 'C') {
                                Write-Host "`nClear this terminal"
                                Start-Sleep -Milliseconds 500
                                Clear-Host
                                continue
                            }
                        }
                    }
                    
                    # 출력 완료 후 네임스페이스 선택으로 돌아가기 위해 $ORDER에 1을 할당하고 while문 다시 수행
                    $ORDER = 1
                    continue
                }

                # sum, --containers 옵션 없는 경우
                catch{
                    
                    # kubectl top에 --sum과 --containers 옵션이 포함되어 있지 않다는 메시지 출력
                    Write-Host "'--sum' " -NoNewline -ForegroundColor Red; Write-Host "and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Red; Write-Host " options does not exist";

                    # 호스트 출력을 지움 -> 커서 위치가 최상단으로 변경됨
                    Clear-Host

                    # 현재 커서 위치(최상단)를 변수에 지정
                    $CURRENTCURSORPOSITION = $Host.UI.RawUI.CursorPosition

                    # 선택한 네임스페이스에 대해 출력
                    while(1){

                        $DATE = (Get-Date -Format 'yyyy-MM-dd HH:mm.fff')

                        # kubectl 결과값을 변수에 할당
                        $RESULT = $(kubectl top pods --kubeconfig ${KUBECONFIG_PATH})

                        # 현재 커서 위치(최상단) 변수를 최상단으로 변경
                        $Host.UI.RawUI.CursorPosition = $CURRENTCURSORPOSITION
                        
                        # 결과값 출력
                        Write-Host "${DATE}"
                        Write-Host -NoNewline "------------------------------------------------"; Write-Host -NoNewline "$NAMESPACE".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue; Write-Host "------------------------------------------------";
                        $RESULT -split '\r?\n' | ForEach-Object { Write-Host "$_" }
                        Write-Host "------------------------------------------------------------------------------------------------" -NoNewline; Write-Host ("-" * ($NAMESPACE).Length);

                        # 사용자 입력에 따른 안내문 출력
                        Write-Host "Press " -NoNewline; Write-Host "'q'" -NoNewline -ForegroundColor Yellow; Write-Host " to quit this step.";
                        Write-Host "Press " -NoNewline; Write-Host "'c'" -NoNewline -ForegroundColor Yellow; Write-Host " to clear this terminal." -NoNewline;

                        # 사용자가 입력에 따라 다음을 수행
                        if ([System.Console]::KeyAvailable) {
                            $KEY = [System.Console]::ReadKey($true)

                            # q를 입력하면 while문 종료
                            if ($KEY.KeyChar -eq 'q' -or $KEY.KeyChar -eq 'Q') {
                                Write-Host "`nQuit this step"
                                break
                            }
                            
                            # c를 입력하면 clear 수행
                            elseif ($KEY.KeyChar -eq 'c' -or $KEY.KeyChar -eq 'C') {
                                Write-Host "`nClear this terminal"
                                Start-Sleep -Milliseconds 500
                                Clear-Host
                                continue
                            }
                        }
                    }

                    # 출력 완료 후 네임스페이스 선택으로 돌아가기 위해 $ORDER에 1을 할당하고 while문 다시 수행
                    $ORDER = 1
                    continue
                }
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return 0
            }

            # 뒤로가기 수행
            5{
                return 1
            }

        }        
    }
}

# 1-4 전체 네임스페이스 상태 점검
function Number1_4 {
    foreach ($KUBECONIFG_FILE in $KUBECONFIG_FILES) {
    Write-Host -NoNewline "----------------------------------------------------------------"
    Write-Host -NoNewline "$(${NAMESPACE_LIST}[$COUNT++])".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue
    Write-Host "----------------------------------------------------------------"
    kubectl get pods -o custom-columns=NAME:.metadata.name,POD_STATUS:.status.phase,CONTAINER_READY:.status.containerStatuses[].ready,RESTART_COUNT:.status.containerStatuses[].restartCount,NODE:.spec.nodeName --kubeconfig $KUBECONFIG\$KUBECONIFG_FILE | Out-Host
    }
}

# 1-5 Deployment CPU, Memory 설정 확인
function Number1_5 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # 컨테이너 선택 & 작업
            2 {                
                kubectl get deployments -o custom-columns="Deployment Name:metadata.name,Replicas:spec.replicas,CPU(limits):spec.template.spec.containers[*].resources.limits.cpu,CPU(requests):spec.template.spec.containers[*].resources.requests.cpu,MEMORY(limits):spec.template.spec.containers[*].resources.limits.memory,MEMORY(requests):spec.template.spec.containers[*].resources.requests.memory" --kubeconfig ${KUBECONFIG_PATH} | ForEach-Object {
                    if ($_ -match 'Deployment Name') {
                        "Deployment Name                                    Replicas     CPU(limits)     CPU(requests)      MEMORY(limits)       MEMORY(requests)"
                        "----------------------------------------------------------------------------------------------------------------------------------------"
                    } 
                    else {
                        $values = $_ -split ' +'
                        "{0,-42} {1,12} {2,14} {3,17} {4,18} {5,20}" -f $values[0],$values[1],$values[2],$values[3],$values[4],$values[5]
                    }
                } | Out-Host

                
                $ORDER = 1
                continue
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return 0
            }

            # 뒤로가기 수행
            5{
                return 1
            }
        }        
    }
}

# 1-6 Ingress Annotation 설정 확인(Timeout 설정 등)
function Number1_6 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # 인그레스 선택
            2 {
                $ORDER = IngressSelect
                continue
            }

            # 컨테이너 선택 & 작업
            3 {
                # Annotation 조회하여 리스트에 할당
                $ANNOTATIONS = kubectl get ingress $($INGRESSES[$INGRESS_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.metadata.annotations}" | ConvertFrom-Json

                # Annotation을 사용자에게 출력
                foreach ($KEY in $ANNOTATIONS.psobject.Properties.Name) {
                    $VALUE = $ANNOTATIONS.$key
                    Write-Host "${KEY}: $VALUE"
                }

                # 인그레스 어노테이션 조회 완료 후 파드 선택 단계부터 재실행
                $ORDER = 2
                continue
            }
            
            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return 0
            }

            # 뒤로가기 수행
            5{
                return 1
            }
        }        
    }
}

# 1-7 프로세스 모니터링 (ps aufxww)
function Number1_7 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # 파드 선택
            2 {
                $ORDER = PodSelect
                continue
            }

            # 컨테이너 선택 & 작업
            3 {
                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){
                
                # 명령어 변수에 할당
                $COMMAND = @'
watch -n 1 "ps aufxww | grep -v $$ | grep -v 'ps aufxww' | grep -v 'watch'"
'@

                # 명령어 수행
                Start-Process -Wait -NoNewWindow -FilePath "kubectl" -ArgumentList "exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c `"$($COMMAND -replace '"', '\"')`""

                # 작업 완료 후 파드 선택 단계부터 재실행
                $ORDER = 2
                continue
            }
                else {

                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red

                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                
                    # 명령어 변수에 할당
                    $COMMAND = @'
watch -n 1 "ps aufxww | grep -v $$ | grep -v 'ps aufxww' | grep -v 'watch'"
'@
                    # 명령어 수행
                    Start-Process -Wait -NoNewWindow -FilePath "kubectl" -ArgumentList "exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c `"$($COMMAND -replace '"', '\"')`""

                    # 작업 완료 후 파드 선택 단계부터 재실행
                    $ORDER = 2
                    continue
                }
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return 0
            }

            # 뒤로가기 수행
            5{
                return 1
            }
        }        
    }
}

# 2-1 파드 로그 출력(Tail)
function Number2_1 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # 파드 선택
            2 {
                $ORDER = PodSelect
                continue
            }

            # 컨테이너 선택 & 작업
            3 {
                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){

                    # "로그 출력 값 입력" 단계 알림 메시치 출력
                    Write-Host "-------로그 출력 값 입력-------" -BackgroundColor Yellow -ForegroundColor Red

                    # 알림 메시지 출력
                    Write-Host "If you want to stream logs in real-time, type " -NoNewline
                    Write-Host "'f'" -ForegroundColor Yellow
                    Write-Host "If you want to show full of logs type " -NoNewline
                    Write-Host "'any key'" -ForegroundColor Yellow

                    # Tail 값 사용자에게 입력 받음
                    while(1){
                        $TAIL = Read-Host "Tail: "
                        if($TAIL -ne ''){
                            break
                        }
                    }

                    # Tail 값이 f인 경우 실시간 로그 출력
                    if($TAIL -eq 'f'){
                        Write-Host "Tail real-time logs of " -NoNewline
                        Write-Host "$($PODS[$POD_SELECTION-1])/$($CONTAINERS[$CONTAINER_SELECTION-1])" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                        kubectl logs $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -f | Out-Host
                    }

                    # Tail 값이 존재하지 않거나, 비정상값일 경우 -> 전체 로그 출력
                    elseif (![int]::TryParse(${TAIL}, [ref]$null)) {
                        Write-Host "Tail full logs of " -NoNewline
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                        kubectl logs $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} | Out-Host
                    }

                    # Tail 값이 존재하는 경우 -> 입력한 tail값 만큼 로그 출력
		            else {
                        Write-Host "Tail ${TAIL} llines of logs of " -NoNewline
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                        kubectl logs $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} --tail ${TAIL} | Out-Host
                    }

                    # 로그 출력 후 파드 선택 단계부터 재실행
                    $ORDER = 2
                    continue
                }
                else {

                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red

                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # "로그 출력 값 입력" 단계 알림 메시치 출력
                    Write-Host "-------로그 출력 값 입력-------" -BackgroundColor Yellow -ForegroundColor Red

                    # 알림 메시지 출력
                    Write-Host "If you want to stream logs in real-time, type " -NoNewline
                    Write-Host "'f'" -ForegroundColor Yellow
                    Write-Host "If you want to show full of logs type " -NoNewline
                    Write-Host "'any key'" -ForegroundColor Yellow

                    # Tail 값 사용자에게 입력 받음
                    while(1){
                        $TAIL = Read-Host "Tail: "
                        if($TAIL -ne ''){
                            break
                        }
                    }

                    # Tail 값이 f인 경우 실시간 로그 출력
                    if($TAIL -eq 'f'){
                        Write-Host "Tail real-time logs of " -NoNewline
                        Write-Host "$($PODS[$POD_SELECTION-1])/$($CONTAINERS[$CONTAINER_SELECTION-1])" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                        kubectl logs $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -f | Out-Host
                    }

                    # Tail 값이 존재하지 않거나, 비정상값일 경우 -> 전체 로그 출력
                    elseif (![int]::TryParse(${TAIL}, [ref]$null)) {
                        Write-Host "Tail full logs of " -NoNewline
                        Write-Host "$($PODS[$POD_SELECTION-1])/$($CONTAINERS[$CONTAINER_SELECTION-1])" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                        kubectl logs $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} | Out-Host
                    }

                    # Tail 값이 존재하는 경우 -> 입력한 tail값 만큼 로그 출력
		            else {
                        Write-Host "Tail ${TAIL} llines of logs of " -NoNewline
                        Write-Host "$($PODS[$POD_SELECTION-1])/$($CONTAINERS[$CONTAINER_SELECTION-1])" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                        kubectl logs $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1])  --kubeconfig ${KUBECONFIG_PATH} --tail ${TAIL} | Out-Host
                    }

                    # 로그 출력 후 파드 선택 단계부터 재실행
                    $ORDER = 2
                    continue
                }
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return 0
            }

            # 뒤로가기 수행
            5{
                return 2
            }
        }        
    }
}

# 2-2 파드 로그 로컬 다운로드
function Number2_2 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){

        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # 파드 선택
            2 {
                $ORDER = PodSelect
                continue
            }

            # 컨테이너 선택 & 작업
            3 {

                # 로그가 저장될 경로를 변수로 지정
                
                $LOG_PATH = "$HOME\Desktop\Pod_logs\${NAMESPACE}"

		        # 로그를 저장할 경로가 없을 경우 생성
                if (-not (Test-Path $LOG_PATH)) {
                    New-Item -ItemType Directory -Path $LOG_PATH
                }

                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){

                    # 로그 파일 저장
                    $DATE = Get-Date -Format "yyyy/MM/dd/HH/mm"
                    Write-Host "Saved to " -NoNewline
                    Write-Host "$LOG_PATH\$($PODS[$POD_SELECTION-1])_${DATE}.txt" -ForegroundColor Yellow
		            kubectl logs $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} > $LOG_PATH\$($PODS[$POD_SELECTION-1])_${DATE}.txt

                    # 저장된 로그파일을 열것인지 선택
                    Write-Host "type '" -NoNewline; Write-Host "y" -NoNewline -ForegroundColor Yellow; Write-Host "' to open a log file";
                    Write-Host "type '" -NoNewline; Write-Host "any key" -NoNewline -ForegroundColor Yellow; Write-Host "' to skip";
                    $OPEN_LOG_FILE = Read-Host " "

                    # y를 입력할 경우 저장된 로그파일을 notepad로 오픈
                    if($OPEN_LOG_FILE -eq "y" -or $OPEN_LOG_FILE -eq "Y") {
                        Write-Host "Now opening " -NoNewline
                        Write-Host "$LOG_PATH\$($PODS[$POD_SELECTION-1])_${DATE}.txt" -ForegroundColor Yellow
                        notepad $LOG_PATH\$($PODS[$POD_SELECTION-1])_${DATE}.txt
                    }

                    # 로그 파일 저장 완료 후 파드 선택 단계부터 재실행
                    $ORDER = 2
                    continue
                }

                # 파드내 컨테이너가 2개 이상인 경우
                else {
                    
                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red

                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # 로그 파일 저장
                    $DATE = Get-Date -Format "yyyy/MM/dd/HH/mm"
                    Write-Host "Saved to " -NoNewline
                    Write-Host "$LOG_PATH\$($PODS[$POD_SELECTION-1])_$($CONTAINERS[$CONTAINER_SELECTION-1])_${DATE}.txt" -ForegroundColor Yellow
		            kubectl logs $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} > $LOG_PATH\$($PODS[$POD_SELECTION-1])_$($CONTAINERS[$CONTAINER_SELECTION-1])_${DATE}.txt

                    # 저장된 로그파일을 열것인지 선택
                    Write-Host "type '" -NoNewline; Write-Host "y" -NoNewline -ForegroundColor Yellow; Write-Host "' to open a log file";
                    Write-Host "type '" -NoNewline; Write-Host "any key" -NoNewline -ForegroundColor Yellow; Write-Host "' to skip";
                    $OPEN_LOG_FILE = Read-Host " "
                    
                    # y를 입력할 경우 저장된 로그파일을 notepad로 오픈
                    if($OPEN_LOG_FILE -eq "y" -or $OPEN_LOG_FILE -eq "Y") {
                        Write-Host "Now opening " -NoNewline
                        Write-Host "$LOG_PATH\$($PODS[$POD_SELECTION-1])_$($CONTAINERS[$CONTAINER_SELECTION-1])_${DATE}.txt" -ForegroundColor Yellow
                        notepad $LOG_PATH\$($PODS[$POD_SELECTION-1])_$($CONTAINERS[$CONTAINER_SELECTION-1])_${DATE}.txt
                    }

                    # 로그 파일 저장 완료 후 파드 선택 단계부터 재실행
                    $ORDER = 2
                    continue
                }
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return 0
            }

            # 뒤로가기 수행
            5{
                return 2
            }
        }        
    }
}

# 2-3 Nginx Ingress Controller 로그 실시간 확인(access.log, error.log)
function Number2_3 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # Nginx Ingress Controller 선택
            2 {

                # Nginx Ingress Controller Pod 를 파싱하여 변수에 할당
                $NGINX_PODS = (kubectl get pods --selector app=ingress-controller -o=name --kubeconfig ${KUBECONFIG_PATH}).replace("pod/","")
                
                # Nginx Ingress Controller 가 1개일 경우
                if( $(${NGINX_PODS}.Count) -eq 1 ){
                    $NGINX_POD = $NGINX_PODS
                    Write-Host "Selected Nginx Ingress Controller: " -NoNewline
                    Write-Host "$NGINX_POD" -ForegroundColor Blue
                    # 로그 확인 완료 후 네임스페이스 선택 단계로 돌아가기 위해 ORDER변수에 1을 할당하고 continue 수행
                    $ORDER = 3
                    continue
                }

                # Nginx Ingress Controller 가 2개 이상일 경우
                else {
                    
                    # "인그레스 컨트롤러 파드 선택" 단계 알림 메시치 출력
                    Write-Host "-------인그레스 컨트롤러 파드 선택-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0
                    
                    # 사용자에게 인그레스 컨트롤러 선택지를 출력
                    Write-Host "Select Nginx Ingress Controller" -ForegroundColor Yellow
                    foreach (${NGINX_POD} in $NGINX_PODS) {
                        $COUNT++
                        Write-Host "${COUNT}: $NGINX_POD"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message

                    # 사용자의 Nginx Ingress Controller 선택을 입력 받아 변수 할당
                    while(1) {
                        $NGINX_SELECTION = Read-Host " "
                        if($NGINX_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${NGINX_SELECTION} -eq "q" -or ${NGINX_SELECTION} -eq "f" -or ${NGINX_SELECTION} -eq "b" -or ${NGINX_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b1_r2 -Selection ${NGINX_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${NGINX_SELECTION}, [ref]$null) -or [int]${NGINX_SELECTION} -lt 1 -or [int]${NGINX_SELECTION} -gt $($NGINX_PODS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($NGINX_PODS.Count)" -ForegroundColor Red
                        continue
                    }

                    # 사용자가 정상적인 값을 입력했을 경우
                    else {
                        $NGINX_POD = $($NGINX_PODS[$NGINX_SELECTION-1])
                        Write-Host "Selected Nginx Ingress Controller: " -NoNewline
                        Write-Host "$NGINX_POD" -ForegroundColor Blue
                    }
                    
                    # 로그 확인 단계로 넘어가기 위해 ORDER변수에 3을 할당하고 continue 수행
                    $ORDER = 3
                    continue
                }
            }

            # access.log 또는 error.log 선택
            3 {

                # "로그 파일 선택" 단계 알림 메시치 출력
                Write-Host "-------로그 파일 선택-------" -BackgroundColor Yellow -ForegroundColor Red
                # 1 을 입력하면 access.log 를 확인한다는 메시지 출력
                Write-Host "1: " -NoNewline
                Write-Host "access.log"
                
                # 2 을 입력하면 error.log 를 확인한다는 메시지 출력
                Write-Host "2: " -NoNewline
                Write-Host "error.log"

                # 스크립트 단계 이동 조건 출력
                Message_NoRefresh

                # 사용자의 Nginx Ingress Controller 선택을 입력 받아 변수 할당
                while(1) {
                    $LOG_SELECTION = Read-Host ' '
                    if($LOG_SELECTION -ne ''){
                        break
                    }
                }
                
                # 사용자 선택 값을 확인 (Nginx Ingress Controller가 1개인 경우)
                if ($($NGINX_PODS.Count) -eq 1 -and (${LOG_SELECTION} -eq "q" -or ${LOG_SELECTION} -eq "f" -or ${LOG_SELECTION} -eq "b")){
                    $ORDER = Check_Selection_b1_r2 -Selection ${LOG_SELECTION}
                    continue
                }

                # 사용자 선택 값을 확인 (Nginx Ingress Controller가 2개 이상인 경우)
                elseif ($($NGINX_PODS.Count) -ge 2 -and (${LOG_SELECTION} -eq "q" -or ${LOG_SELECTION} -eq "f" -or ${LOG_SELECTION} -eq "b")){
                    $ORDER = Check_Selection_b2_r3 -Selection ${LOG_SELECTION}
                    continue
                }

                # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                elseif (![int]::TryParse(${LOG_SELECTION}, [ref]$null) -or [int]${LOG_SELECTION} -lt 1 -or [int]${LOG_SELECTION} -gt 2 ) {
                    Write-Host "Invalid selection. Please enter a number between 1 and 2" -ForegroundColor Red
                    continue
                }
                
                # 사용자가 1을 선택할 경우 access.log 출력
                elseif (${LOG_SELECTION} -eq 1) {

                    # 로그 확인 대상 출력
                    Write-Host "Checking real-time log of access.log of " -NoNewline; Write-Host "${NGINX_POD}" -ForegroundColor Green

                    # access.log 확인
                    kubectl exec -it ${NGINX_POD} -c ingress-controller --kubeconfig ${KUBECONFIG_PATH} -- tail -f /var/log/nginx/access.log | Out-Host
                    
                }

                # 사용자가 2을 선택할 경우 error.log 출력
                elseif (${LOG_SELECTION} -eq 2) {

                    # 로그 확인 대상 출력
                    Write-Host "Checking real-time log of error.log of " -NoNewline; Write-Host "${NGINX_POD}" -ForegroundColor Green

                    # error.log 확인
                    kubectl exec -it ${NGINX_POD} -c ingress-controller --kubeconfig ${KUBECONFIG_PATH} -- tail -f /var/log/nginx/error.log | Out-Host


                }

                # Nginx Ingrss Controller가 1개인 경우 로그 tail 을 종료하고 다시 네임스페이스 선택으로 돌아가기 위해 ORDER 변수에 1을 할당하고 continue
                if ($($NGINX_PODS.Count) -eq 1) {
                    $ORDER = 1
                    continue
                }
                # Nginx Ingrss Controller가 2개 이상인 경우 로그 tail 을 종료하고 다시 Nginx Ingress Controller 선택으로 돌아가기 위해 ORDER 변수에 2를 할당하고 continue
                elseif ($($NGINX_PODS.Count) -ge 2) {
                    $ORDER = 2
                    continue
                }
            }
            
            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return 0
            }

            # 뒤로가기 수행
            5{
                return 2
            }
        }    
    }
}

# 3-1 JSTAT 확인
function Number3_1 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){

        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # 파드 선택
            2 {
                $ORDER = PodSelect
                continue
            }

            # 컨테이너 선택 & 작업
            3 {

                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){
                    
                    # 사용자에게 "JSTAT 출력중" 메시지 출력
                    Write-Host -NoNewline "Watching JSTAT to "
                    Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green
                    
                    # 선택된 파드에서 JSTAT 확인
                    try{

                        # 프로세스 ID 변수 할당
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server" 2> $null

                        # 제우스 파드가 아닐 경우 에러 처리
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # 제우스 파드가 맞을 경우 정상적으로 명령어 수행
                        else{
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- jstat -gcutil -h20 -t $PROCESS_ID 2000 | Out-Host
                        }
                    }
                    catch{

                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 파드" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # JSTAT 출력 완료 후 파드 선택 단계로 돌아가는 설정
                    $ORDER = 2
                    continue
                }

                # 파드내 컨테이너가 2개 이상일 경우
                else {
                    
                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # 사용자에게 "JSTAT 출력중" 메시지 출력
                    Write-Host -NoNewline "Watching JSTAT from "
                    Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green

                    # 선택된 파드에서 JSTAT 확인
                    try{

                        # 프로세스 ID 변수 할당
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # 제우스 컨테이너가 아닐 경우 에러 처리
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # 제우스 컨테이너가 맞을 경우 정상적으로 명령어 수행
                        else{
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- jstat -gcutil -h20 -t $PROCESS_ID 2000 | Out-Host
                        }
                    }
                    catch{
                        
                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 컨테이너" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # JSTAT 출력 완료 후 파드 선택 단계로 돌아가는 설정
                    $ORDER = 2
                    continue
                    
                }
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return 0
            }

            # 뒤로가기 수행
            5{
                return 3
            }
        }        
    }
}

# 3-2 JVM Heap 덤프 파일 로컬 다운로드
function Number3_2 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # 파드 선택
            2 {
                $ORDER = PodSelect
                continue
            }

            # 컨테이너 선택 & 작업
            3 {

                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파일 생성을 위한 DATE 변수 할당
                $DATE = Get-Date -Format "yyMMdd_HHmm"

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){

                    # 힙 덤프 생성 메시지 출력
                    Write-Host -NoNewline "Creating heap dump file to "
                    Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                    # 선택된 파드에서 힙 덤프 생성
                    try{

                        # 프로세스 ID 변수 할당
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # 제우스 컨테이너가 아닐 경우 에러 처리
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # 제우스 컨테이너가 맞을 경우 정상적으로 명령어 수행
                        else{

                            # jmap 명령어 변수 할당
                            $COMMAND = "jmap -dump:format=b,file=$($PODS[$POD_SELECTION-1])_${DATE}.hprof ${PROCESS_ID}"
                            
                            # 컨테이너 내에 임시로 생성될 힙 덤프 경로 지정
                            $CONTAINER_PATH = "$($PODS[$POD_SELECTION-1]):$($PODS[$POD_SELECTION-1])_${DATE}.hprof"

                            # 로컬 저장 경로 지정
                            $LOCAL_PATH = $HOME.replace("C:","").replace("\","/") + "/Desktop/$($PODS[$POD_SELECTION-1])_${DATE}.hprof"
                            
                            # 선택된 파드에서 힙 덤프 생성
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c ${COMMAND} | Out-Host

                            #  힙 덤프 로컬 다운로드
                            Write-Host "Downloading heap dump file to $LOCAL_PATH ..."
                            kubectl cp $CONTAINER_PATH $LOCAL_PATH --kubeconfig ${KUBECONFIG_PATH} --warnings-as-errors=false | Out-Host

                            # 컨테이너 내에 생성했던 임시 힙 덤프 파일 삭제
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- rm ./$($PODS[$POD_SELECTION-1])_${DATE}.hprof | Out-Host
                        }
                    }
                    catch{
                        
                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 파드" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }



                    # 힙 덤프 다운로드 완료 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 2
                    continue
                }
                else {
                    
                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # 힙 덤프 생성 메시지 출력
                    Write-Host -NoNewline "Creating heap dump file to "
                    Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green

                    # 선택된 파드에서 힙 덤프 생성
                    try{

                        # 프로세스 ID 변수 할당
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # 제우스 컨테이너가 아닐 경우 에러 처리
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # 제우스 컨테이너가 맞을 경우 정상적으로 명령어 수행
                        else{
                            # jmap 명령어 변수 할당
                            $COMMAND = "jmap -dump:format=b,file=$($PODS[$POD_SELECTION-1])_${DATE}.hprof ${PROCESS_ID}"
                            
                            # 컨테이너 내에 임시로 생성될 힙 덤프 경로 지정
                            $CONTAINER_PATH = "$($PODS[$POD_SELECTION-1]):$($PODS[$POD_SELECTION-1])_${DATE}.hprof"
                            
                            # 로컬 저장 경로 지정
                            $LOCAL_PATH = $HOME.replace("C:","").replace("\","/") + "/Desktop/$($PODS[$POD_SELECTION-1])_${DATE}.hprof"

                            # 선택된 파드에서 힙 덤프 생성
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c ${COMMAND} | Out-Host
                            Write-Host "Downloading heap dump file to $LOCAL_PATH ..."

                            #  힙 덤프 로컬 다운로드
                            kubectl cp -c $($CONTAINERS[$CONTAINER_SELECTION-1]) $CONTAINER_PATH $LOCAL_PATH --kubeconfig ${KUBECONFIG_PATH} --warnings-as-errors=false | Out-Host

                            # 컨테이너 내에 생성했던 임시 힙 덤프 파일 삭제
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- rm ./$($PODS[$POD_SELECTION-1])_${DATE}.hprof | Out-Host
                        }
                    }
                    catch{
                        
                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 컨테이너" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # 힙 덤프 다운로드 완료 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 2
                    continue
                    
                }
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return 0
            }

            # 뒤로가기 수행
            5{
                return 3
            }
        }        
    }
}

# 3-3 jinfo 확인
function Number3_3 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # 파드 선택
            2 {
                $ORDER = PodSelect
                continue
            }

            # 컨테이너 선택 & 작업
            3 {

                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){
                    
                    # 안내 메시지 출력
                    Write-Host -NoNewline "Checking jinfo of "
                    Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                    # 선택된 파드에서 jinfo 확인
                    try{

                        # 프로세스 ID 변수 할당
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # 제우스 컨테이너가 아닐 경우 에러 처리
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # 제우스 컨테이너가 맞을 경우 정상적으로 명령어 수행
                        else{
                            
                            # jinfo 명령어 변수 할당
                            $COMMAND = "jinfo ${PROCESS_ID}"

                            # 선택된 파드에서 jinfo 확인
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c ${COMMAND} | Out-Host
                        }
                    }
                    catch{
                        
                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 파드" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }


                    
                    # jinfo 확인 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 2
                    continue
                }

                # 파드내 컨테이너가 2개 이상일 경우
                else {
                                        
                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                    
                    # 안내 메시지 출력
                    Write-Host -NoNewline "Checking jinfo of "
                    Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green

                    # 선택된 파드에서 jinfo 확인
                    try{

                        # 프로세스 ID 변수 할당
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # 제우스 컨테이너가 아닐 경우 에러 처리
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # 제우스 컨테이너가 맞을 경우 정상적으로 명령어 수행
                        else{
                            
                            # jinfo 명령어 변수 할당
                            $COMMAND = "jinfo ${PROCESS_ID}"

                            # 선택된 파드 컨테이너에서 jinfo 확인
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c ${COMMAND} | Out-Host
                        }
                    }
                    catch{
                        
                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 컨테이너" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # jinfo 확인 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 2
                    continue
                    
                }
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return 0
            }

            # 뒤로가기 수행
            5{
                return 3
            }
        }        
    }
}

# 3-4 jstack 조회
function Number3_4 {

    # 함수의 ORDER 변수를 통해 뒤로가기, 맨 처음단계로 이동, 새로고침 등을 구현
    param (
        $ORDER
    )

    # 단계 이동을 위해 While문과 Switch문 사용
    while(1){
        Switch ($ORDER) {

            # 네임스페이스 선택
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # 파드 선택
            2 {
                $ORDER = PodSelect
                continue
            }

            # 컨테이너 선택 & 작업
            3 {

                # 컨테이너 목록 리스트에 할당
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # 파드내 컨테이너가 1개일 경우
                if( $($CONTAINERS.Count) -eq 1 ){
                    
                    # 안내메시지 출력
                    Write-Host -NoNewline "Checking jstack of "
                    Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                    # 선택된 파드에서 jstack 확인
                    try{

                        # 프로세스 ID 변수 할당
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # 제우스 컨테이너가 아닐 경우 에러 처리
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # 제우스 컨테이너가 맞을 경우 정상적으로 명령어 수행
                        else{
                            
                            # jstack 명령어 변수 할당
                            $COMMAND = "jstack -F ${PROCESS_ID}"

                            # 선택된 파드에서 jstack 확인
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c ${COMMAND} | Out-Host
                        }
                    }
                    catch{
                        
                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 파드" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # jstack 확인 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 2
                    continue
                }

                # 파드내 컨테이너가 2개 이상일 경우
                else {
                    
                    # "컨테이너 선택" 단계 알림 메시치 출력
                    Write-Host "-------컨테이너 선택-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # 사용자가 유효하지 않은 값을 입력하여 다시 수행할 경우를 위해 변수값을 0으로 초기화
                    [int]$COUNT = 0

                    # 사용자에게 컨테이너 선택지를 출력
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # 스크립트 단계 이동 조건 출력
                    Message

                    # 사용자의 컨테이너 선택을 입력 받아 변수 할당
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # 사용자 선택 값을 확인
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # 사용자가 유효하지 않은 값을 입력할 경우 while 루프 처음부터 진행
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # 선택된 파드에서 jstack 확인
                    Write-Host -NoNewline "Checking jstack of "
                    Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green
		            
                    # 선택된 파드에서 jstack 확인
                    try{

                        # 프로세스 ID 변수 할당
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # 제우스 컨테이너가 아닐 경우 에러 처리
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # 제우스 컨테이너가 맞을 경우 정상적으로 명령어 수행
                        else{
                            
                            # jstack 명령어 변수 할당
                            $COMMAND = "jstack -F ${PROCESS_ID}"

                            # 선택된 파드 컨테이너에서 jstack 확인
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c ${COMMAND} | Out-Host
                        }
                    }
                    catch{
                        
                        # 오류메시지 출력
                        Write-Host "반드시 " -NoNewline; Write-Host "Jeus 컨테이너" -NoNewline -ForegroundColor Red; Write-Host "를 선택하세요.";
                    }

                    # jstack 확인 후 파드 선택 단계로 돌아가기 위한 설정
                    $ORDER = 2
                    continue
                }
            }

            # 파드, 네임스페이스, 인그레스 선택등에서 f 입력을 받은 경우 맨 처음 단계로 돌아가기 위해 ORDER변수에 4를 할당하여 return 수행
            4{
                return 0
            }

            # 뒤로가기 수행
            5{
                return 3
            }
        }        
    }
}

# 작업 선택 실행
SelectJob -STEP 0


'''
2.0.4 Patch Note
230731
- "4. Jeus Admin 명령어 모음 -> 네임스페이스 선택 -> 파드 선택" 에서 f를 입력하여 맨 처음 단계로 이동할 경우 불필요한 0 이 출력 되는 현상 수정

2.0.5 Patch Note
231010
- 파드쉘 접속 명령어 수정 sh -c "clear; (bash || ash || sh)" 를 /bin/bash 로 수정

'''