#################################################################################################################
# ������: ������
# Description: �� ���� ���Ǹ� ���� �ۼ��� �Ŀ��� ��ũ��Ʈ�� kubectl���� �������� �ʴ� ��� �Ǵ� ���� �ڵ�ȭ ����
#################################################################################################################

# ���� ����
$Last_Updated = "23.10.10"
$VERSION = "2.0.5"
$KUBECONFIG = "$HOME\Desktop\kubeconfig"
$KUBECONFIG_FILES = @()
$NAMESPACE_LIST = @()

# Kubectl�� ��ġ�Ǿ� �ִ��� Ȯ�� -> ��ġ �ȵǾ� �ִ� ��� �ȳ� �޽��� ��� �� ��ũ��Ʈ ����
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "kubectl�� ��ġ�Ǿ����� �ʽ��ϴ�. kubectl�� ��ġ �� ��ũ��Ʈ�� �ٽ� �������ּ���." -ForegroundColor Red
    exit 0
}

# KUBECONFIG ���͸��� ���� ��� ���͸� ���� �� �ȳ� �޽��� ���
if (-not (Test-Path $KUBECONFIG)) {
    New-Item -ItemType Directory -Path $KUBECONFIG
    Write-Host "Please copy all of the kubeconfig files to the following path: " -NoNewline; Write-Host "$KUBECONFIG" -ForegroundColor Green
    exit 0
}

# kubeconfig ������ �������� ���� ��� �˸� �޽��� ���
if (-not (Test-Path $KUBECONFIG\*kubeconfig*)) {
    Write-Host "kubeconfig ������ $KUBECONFIG\ ��ο� �������� �ʽ��ϴ�. ���� �̸��� kubeconfig �� �ݵ�� �����ϼ���." -ForegroundColor Red
    exit 0
}

# ��ũ��Ʈ ���� �� ������Ʈ ��¥ ���
Write-Host "Version: " -NoNewline; Write-Host "${VERSION} " -NoNewline -ForegroundColor Green; Write-Host "/ Last Updated at " -NoNewline; Write-Host "${Last_Updated}" -ForegroundColor Green;

# edit������ Kubeconfig ���Ͽ��� ���ӽ����̽� �Ľ� -> ����ڿ��� ���ӽ����̽� ������� �� ���
Select-String -Path "$KUBECONFIG\*edit*" -Pattern "namespace" | foreach-object {
    $KUBECONFIG_FILE = $_.Filename
    $LINE = $_.Line
    $NAMESPACES = $line.Substring($LINE.IndexOf(":") + 2)
    $KUBECONFIG_FILES += $KUBECONFIG_FILE
    $NAMESPACE_LIST += $NAMESPACES
}

# ������ �۾� ��� �ؽ����̺� (Ordered)
$CHOICES = [ordered]@{
    ' 1.' = '���ҽ� ����/���� ���� �� ����͸�'
    ' 2.' = '�α� ���/�ٿ�ε�'
    ' 3.' = 'Java ��ɾ� ����'
    ' 4.' = 'Jeus Admin ��ɾ� ����'
    ' 5.' = '�ĵ� �� ����'
    ' 6.' = 'Network Policy �ڵ� ����(SKE ������ ���̵�)'
    ' 7.' = '���� ���� (�����̳� <-> ���� PC)'
    ' 8.' = 'DB Ŀ�ؼ� �׽�Ʈ'
}

$CHOICES_STATUS_CHECK = [ordered]@{
    ' 1.' = '��� ���ӽ����̽��� POD CPU/Memory ���� ���� ��ȸ'
    ' 2.' = 'Ư�� ���ӽ����̽��� Pod CPU/Memory ���� ���� ��ȸ'
    ' 3.' = 'CPU, Memory �ǽð� ����͸�'
    ' 4.' = '��ü ���ӽ����̽� ���� ����'
    ' 5.' = 'Deployment CPU, Memory ���� Ȯ��'
    ' 6.' = 'Ingress Annotation ���� Ȯ��(Timeout ���� ��)'
    ' 7.' = '���μ��� ����͸� (ps aufxww)'
}

$CHOICES_LOG = [ordered]@{
    ' 1.' = '�ĵ� �α� ���(Tail)'
    ' 2.' = '�ĵ� �α� ���� �ٿ�ε�'
    ' 3.' = 'Nginx Ingress Controller �α� �ǽð� Ȯ��(access.log, error.log)'
}

$CHOICES_JAVA = [ordered]@{
    ' 1.' = 'JSTAT Ȯ��'
    ' 2.' = 'JVM Heap ���� ���� ���� �ٿ�ε�'
    ' 3.' = 'jinfo Ȯ��'
    ' 4.' = 'jstack Ȯ��'
}

$CHOICES_JEUS_ADMIN = [ordered]@{
    ' 1.' = 'jeus_admin ����'
    ' 2.' = 'corelated server ��ȸ'
    ' 3.' = 'show-web-statistics Ȯ��'
    ' 4.' = 'server information ��ȸ'
    ' 5.' = 'list-servers Ȯ��'
}

# �۾� ����
function SelectJob {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $STEP
    )
    
    # ����ڰ� ��ȿ���� ���� ������ �� ��� SelectJob �Լ��� ó������ �����ϵ��� �ϱ� ���� While�� ���
    while(1){
        Switch($STEP){

            # �۾� ����
            '0'{

                # "�۾� ����" �ܰ� �˸� �޽�ġ ���
                Write-Host "-------�۾� ����-------" -BackgroundColor Yellow -ForegroundColor Red

                # ����ڿ��� �۾� ��� ���
                foreach ($CHOICE in $CHOICES.GetEnumerator()) {
                Write-Host "$($CHOICE.Key) $($CHOICE.Value)"
                }

                # q�� �Է��ϸ� ��ũ��Ʈ�� ����ȴٴ� �޽��� ���
                Write-Host "Type " -NoNewline
                Write-Host "'q'"  -ForegroundColor Magenta -NoNewline
                Write-Host " to quit this script"

                # ������� �۾� ������ �Է� �޾� ���� �Ҵ�
                while(1){
                    $JOB = Read-Host "Choose an action"
                    if($JOB -ne '') {
                        break
                    }
                }

                # q�� �Է��� ��� ��ũ��Ʈ ����
                if ($JOB -eq "q") {
                    exit 0
                }

                # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� �ȳ� �޽��� ��� �� SelectJob �ٽ� ����
                elseif (![int]::TryParse($JOB, [ref]$null) -or [int]${JOB} -lt 1 -or [int]${JOB} -gt $($CHOICES.Count) ) {
                    Write-Host "Invalid selection. Please enter a number between 1 and $($CHOICES.Count)" -ForegroundColor Red
                    continue
                }
                
                # ���ҽ� ����/���� ���� �ܰ�� �̵�
                elseif( $JOB -eq "1") {
                    $STEP = 1
                    continue
                }

                # �α� ���/�ٿ�ε� �ܰ�� �̵�
                elseif( $JOB -eq "2") {
                    $STEP = 2
                    continue
                }
                
                # Java ��ɾ� ���� �ܰ�� �̵�
                elseif( $JOB -eq "3") {
                    $STEP = 3
                    continue
                }

                # Jeus Admin ��ɾ� ���� �ܰ�� �̵�
                elseif( $JOB -eq "4") {
                    Number0_4 -ORDER 1
                    continue
                }

                # �ĵ� �� ����
                elseif( $JOB -eq "5") {
                    Number0_5 -ORDER 1
                    continue
                }
                
                # Network Policy �ڵ� ����(SKE ������ ���̵�)
                elseif( $JOB -eq "6") {
                    Number0_6 -ORDER 1
                    continue
                }

                # ���� ���� (�����̳� <-> ���� PC)
                elseif( $JOB -eq "7") {
                    Number0_7 -ORDER 1
                    continue
                }

                # DB Ŀ�ؼ� �׽�Ʈ
                elseif( $JOB -eq "8") {
                    Number0_8 -ORDER 1
                    continue
                }
            }

            # ���ҽ� ����/���� ���� �� ����͸�
            '1'{

                # "���ҽ� ����/���� ���� ����" �ܰ� �˸� �޽�ġ ���
                Write-Host "-------���ҽ� ����/���� ���� �۾� ����-------" -BackgroundColor Yellow -ForegroundColor Red

                # ����ڿ��� �۾� ��� ���
                foreach ($CHOICE in $CHOICES_STATUS_CHECK.GetEnumerator()) {
                Write-Host "$($CHOICE.Key) $($CHOICE.Value)"
                }

                # �ȳ� �޽��� ���
                Message_Quit_Back


                # ������� �۾� ������ �Է� �޾� ���� �Ҵ�
                while(1){
                    $JOB = Read-Host "Choose an action"
                    if($JOB -ne '') {
                        break
                    }
                }

                # q�� �Է��� ��� ��ũ��Ʈ ����
                if ($JOB -eq "q") {
                    exit 0
                }

                # b�� �Է��� ��� �ڷΰ���
                elseif($JOB -eq "b") {
                    $STEP = 0
                    continue
                }

                # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� �ȳ� �޽��� ��� �� SelectJob �ٽ� ����
                elseif (![int]::TryParse($JOB, [ref]$null) -or [int]${JOB} -lt 1 -or [int]${JOB} -gt $($CHOICES_STATUS_CHECK.Count) ) {
                    Write-Host "Invalid selection. Please enter a number between 1 and $($CHOICES_STATUS_CHECK.Count)" -ForegroundColor Red
                    continue
                }

                # ��� ���ӽ����̽��� POD CPU/Memory ���� ���� ��ȸ
                elseif($JOB -eq 1){
                    Number1_1
                }

                # Ư�� ���ӽ����̽��� Pod CPU/Memory ���� ���� ��ȸ
                elseif($JOB -eq 2){
                    $STEP = Number1_2 -ORDER 1
                    continue
                }

                # CPU, Memory �ǽð� ����͸�
                elseif($JOB -eq 3){
                    $STEP = Number1_3 -ORDER 1
                    continue
                }

                # ��ü ���ӽ����̽� ���� ����
                elseif($JOB -eq 4){
                    Number1_4
                }

                # Deployment CPU, Memory ���� Ȯ��
                elseif($JOB -eq 5){
                    $STEP = Number1_5 -ORDER 1
                    continue
                }

                # Ingress Annotation ���� Ȯ��(Timeout ���� ��)
                elseif($JOB -eq 6){
                    $STEP = Number1_6 -ORDER 1
                    continue
                }
                
                # ���μ��� ����͸� (ps aufxww)
                elseif($JOB -eq 7){
                    $STEP = Number1_7 -ORDER 1
                    continue
                }
            }

            # �α� ���/�ٿ�ε�
            '2'{

                # "�α� ���/�ٿ�ε�" �ܰ� �˸� �޽�ġ ���
                Write-Host "-------�α� ���/�ٿ�ε� �۾� ����-------" -BackgroundColor Yellow -ForegroundColor Red

                # ����ڿ��� �۾� ��� ���
                foreach ($CHOICE in $CHOICES_LOG.GetEnumerator()) {
                Write-Host "$($CHOICE.Key) $($CHOICE.Value)"
                }

                # �ȳ� �޽��� ���
                Message_Quit_Back

                # ������� �۾� ������ �Է� �޾� ���� �Ҵ�
                while(1){
                    $JOB = Read-Host "Choose an action"
                    if($JOB -ne '') {
                        break
                    }
                }

                # q�� �Է��� ��� ��ũ��Ʈ ����
                if ($JOB -eq "q") {
                    exit 0
                }

                # b�� �Է��� ��� �ڷΰ���
                elseif($JOB -eq "b") {
                    $STEP = 0
                    continue
                }

                # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� �ȳ� �޽��� ��� �� SelectJob �ٽ� ����
                elseif (![int]::TryParse($JOB, [ref]$null) -or [int]${JOB} -lt 1 -or [int]${JOB} -gt $($CHOICES_LOG.Count) ) {
                    Write-Host "Invalid selection. Please enter a number between 1 and $($CHOICES_LOG.Count)" -ForegroundColor Red
                    continue
                }

                # �ĵ� �α� ���(Tail)
                elseif($JOB -eq 1){
                    $STEP = Number2_1 -ORDER 1
                    continue
                }

                # �ĵ� �α� ���� �ٿ�ε�
                elseif($JOB -eq 2){
                    $STEP = Number2_2 -ORDER 1
                    continue
                }

                # Nginx Ingress Controller �α� �ǽð� Ȯ��(access.log, error.log)
                elseif($JOB -eq 3){
                    $STEP = Number2_3 -ORDER 1
                    continue
                }
            }

            # Java ��ɾ� ����
            '3' {

                # "Java ��ɾ� ����" �ܰ� �˸� �޽�ġ ���
                Write-Host "-------Java ��ɾ� ���� �۾� ����-------" -BackgroundColor Yellow -ForegroundColor Red

                # ����ڿ��� �۾� ��� ���
                foreach ($CHOICE in $CHOICES_JAVA.GetEnumerator()) {
                Write-Host "$($CHOICE.Key) $($CHOICE.Value)"
                }

                # �ȳ� �޽��� ���
                Message_Quit_Back

                # ������� �۾� ������ �Է� �޾� ���� �Ҵ�
                while(1){
                    $JOB = Read-Host "Choose an action"
                    if($JOB -ne '') {
                        break
                    }
                }

                # q�� �Է��� ��� ��ũ��Ʈ ����
                if ($JOB -eq "q") {
                    exit 0
                }

                # b�� �Է��� ��� �ڷΰ���
                elseif($JOB -eq "b") {
                    $STEP = 0
                    continue
                }

                # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� �ȳ� �޽��� ��� �� SelectJob �ٽ� ����
                elseif (![int]::TryParse($JOB, [ref]$null) -or [int]${JOB} -lt 1 -or [int]${JOB} -gt $($CHOICES_JAVA.Count) ) {
                    Write-Host "Invalid selection. Please enter a number between 1 and $($CHOICES_JAVA.Count)" -ForegroundColor Red
                    continue
                }
                
                # JSTAT Ȯ��
                elseif($JOB -eq 1){
                    $STEP = Number3_1 -ORDER 1
                    continue
                }

                # JVM Heap ���� ���� ���� �ٿ�ε�
                elseif($JOB -eq 2){
                    $STEP = Number3_2 -ORDER 1
                    continue
                }

                # jinfo Ȯ��
                elseif($JOB -eq 3){
                    $STEP = Number3_3 -ORDER 1
                    continue
                }

                # jstack Ȯ��
                elseif($JOB -eq 4){
                    $STEP = Number3_4 -ORDER 1
                    continue
                }
            }
        }
    }
}

# ���ӽ����̽� ����
function NamespaceSelect {
    while(1){

        # "���ӽ����̽� ����" �ܰ� �˸� �޽�ġ ���
        Write-Host "-------���ӽ����̽� ����-------" -BackgroundColor Yellow -ForegroundColor Red

        # ����ڰ� �߸��� �� �Է��Ͽ� while�� ó������ ������ �� ���� ���� 0���� �ʱ�ȭ
        [int]$NAMESPACE_COUNT = 0

        # ����ڿ��� ���� ������ ���ӽ����̽� ���
        foreach ($PARSING_NAMESPACE in ${NAMESPACE_LIST}) {
            $NAMESPACE_COUNT++
            Write-Host "${NAMESPACE_COUNT}: $PARSING_NAMESPACE"
        }

        Message_Quit_Back

        # ������� ���ӽ����̽� ������ �Է� �޾� ������ �Ҵ�
        while(1){
            $NAMESPACE_SELECTION = Read-Host "Choose a namespace"
            if($NAMESPACE_SELECTION -ne '') {
                break
            }
        }

        # q�� �Է��� ��� ��ũ��Ʈ ����
        if (${NAMESPACE_SELECTION} -eq "q") {
            Write-Host "Quit this script" -ForegroundColor Yellow
            exit 0
        }

        # b�� �Է��� ��� ���� �ܰ�� �̵�
        elseif (${NAMESPACE_SELECTION} -eq "b") {
            Write-Host "Return to the previous step" -ForegroundColor Yellow
            return 4
        }

        # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
        elseif (![int]::TryParse(${NAMESPACE_SELECTION}, [ref]$null) -or [int]${NAMESPACE_SELECTION} -lt 1 -or [int]${NAMESPACE_SELECTION} -gt $($NAMESPACE_LIST.Count) ) {
            Write-Host "Invalid selection. Please enter a number between 1 and $($NAMESPACE_LIST.Count)" -ForegroundColor Red
            continue
        }

        # ����ڰ� ��ȿ�� ���� �Է��� ���
        else{
            # ����ڰ� ��ȿ�� ���� �Է��ϸ� ������ ���ӽ����̽��� $NAMESPACE ������ �Ҵ�
            $global:NAMESPACE = $($NAMESPACE_LIST[${NAMESPACE_SELECTION}-1])
            Write-Host "Selected ${global:NAMESPACE}"

            # ���ӽ����̽� ���ÿ� ���� Kubeconfig ���� ��θ� $KUBECONFIG_PATH�� ������ ����
            $global:KUBECONFIG_PATH = "${KUBECONFIG}\$($KUBECONFIG_FILES[${NAMESPACE_SELECTION}-1])"
            Write-Host "Kubeconfig Path: ${global:KUBECONFIG_PATH}"

            # ���ӽ����̽� ������ ���������� �Ϸ�Ǹ� �����ܰ� ������ ���� "2" �� ���� -> �� �۾� �Լ��� ORDER������ 3 �Ҵ�Ǿ� switch�� ����
            return 2
        }
    }
}

# ���� �۾� ���� �� ���ӽ����̽� ����
function NamespaceSelect_Inner {
    while(1){

        # "���ӽ����̽� ����" �ܰ� �˸� �޽�ġ ���
        Write-Host "-------���ӽ����̽� ����-------" -BackgroundColor Yellow -ForegroundColor Red

        # ����ڰ� �߸��� �� �Է��Ͽ� while�� ó������ ������ �� ���� ���� 0���� �ʱ�ȭ
        [int]$NAMESPACE_COUNT = 0

        # ����ڿ��� ���� ������ ���ӽ����̽� ���
        foreach ($PARSING_NAMESPACE in ${NAMESPACE_LIST}) {
            $NAMESPACE_COUNT++
            Write-Host "${NAMESPACE_COUNT}: $PARSING_NAMESPACE"
        }

        Message_NoRefresh

        # ������� ���ӽ����̽� ������ �Է� �޾� ������ �Ҵ�
        while(1){
            $NAMESPACE_SELECTION = Read-Host "Choose a namespace"
            if($NAMESPACE_SELECTION -ne '') {
                break
            }
        }

        # q�� �Է��� ��� ��ũ��Ʈ ����
        if (${NAMESPACE_SELECTION} -eq "q") {
            Write-Host "Quit this script" -ForegroundColor Yellow
            exit 0
        }

        # b�� �Է��� ��� ���� �ܰ�� �̵�
        elseif (${NAMESPACE_SELECTION} -eq "b") {
            Write-Host "Return to the previous step" -ForegroundColor Yellow
            return 5
        }

        # f�� �Է��� ��� ���� �ܰ�� �̵�
        elseif (${NAMESPACE_SELECTION} -eq "f") {
            Write-Host "Return to the previous step" -ForegroundColor Yellow
            return 4
        }

        # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
        elseif (![int]::TryParse(${NAMESPACE_SELECTION}, [ref]$null) -or [int]${NAMESPACE_SELECTION} -lt 1 -or [int]${NAMESPACE_SELECTION} -gt $($NAMESPACE_LIST.Count) ) {
            Write-Host "Invalid selection. Please enter a number between 1 and $($NAMESPACE_LIST.Count)" -ForegroundColor Red
            continue
        }

        # ����ڰ� ��ȿ�� ���� �Է��� ���
        else{
            # ����ڰ� ��ȿ�� ���� �Է��ϸ� ������ ���ӽ����̽��� $NAMESPACE ������ �Ҵ�
            $global:NAMESPACE = $($NAMESPACE_LIST[${NAMESPACE_SELECTION}-1])
            Write-Host "Selected ${global:NAMESPACE}"

            # ���ӽ����̽� ���ÿ� ���� Kubeconfig ���� ��θ� $KUBECONFIG_PATH�� ������ ����
            $global:KUBECONFIG_PATH = "${KUBECONFIG}\$($KUBECONFIG_FILES[${NAMESPACE_SELECTION}-1])"
            Write-Host "Kubeconfig Path: ${global:KUBECONFIG_PATH}"

            # ���ӽ����̽� ������ ���������� �Ϸ�Ǹ� �����ܰ� ������ ���� "2" �� ���� -> �� �۾� �Լ��� ORDER������ 3 �Ҵ�Ǿ� switch�� ����
            return 2
        }
    }
}

# �ĵ� ����
function PodSelect{

    # "�ĵ� ����" �ܰ� �˸� �޽�ġ ���
    Write-Host "-------�ĵ� ����-------" -BackgroundColor Yellow -ForegroundColor Red

    # ����ڰ� �߸��� �� �Է��Ͽ� while�� ó������ ������ �� ���� ���� 0���� �ʱ�ȭ
	$PODS_COUNT = 0

    # ���õ� ���ӽ����̽��� �ĵ� ����� ����Ʈ�� ����
    $global:PODS =(kubectl get pods -o=name --kubeconfig ${KUBECONFIG_PATH}).replace("pod/","")

    # �ĵ� ��� ���
    foreach ($POD in $global:PODS) {
        $PODS_COUNT++
        Write-Host "${PODS_COUNT}: $POD"
    }

    Message
    
    # ������� �ĵ� ������ �Է� �޾� ������ �Ҵ�
    while(1){
        $global:POD_SELECTION = Read-Host "Choose a pod"
        if($global:POD_SELECTION -ne '') {
            break
        }
    }

    # ����ڰ� q, b, f, r �� �Է��ϴ� ��� 
    if (${global:POD_SELECTION} -eq "q" -or ${global:POD_SELECTION} -eq "b" -or ${global:POD_SELECTION} -eq "f" -or ${global:POD_SELECTION} -eq "r") {
        return Check_Selection_b1_r2 -SELECTION ${global:POD_SELECTION}
    }

    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
    elseif (![int]::TryParse(${global:POD_SELECTION}, [ref]$null) -or [int]${global:POD_SELECTION} -lt 1 -or [int]${global:POD_SELECTION} -gt $($global:PODS.Count) ) {
        Write-Host "Invalid selection. Please enter a number between 1 and $($global:PODS.Count)" -ForegroundColor Red
        return 2
    }

    # �ĵ� ������ ���������� �Ϸ�Ǹ� �����ܰ� ������ ���� "3" �� ���� -> �� �۾� �Լ��� ORDER������ 3 �Ҵ�Ǿ� switch�� ����
    return 3
}

# �α׷��� ����
function IngressSelect{
    
    # "�α׷��� ����" �ܰ� �˸� �޽�ġ ���
    Write-Host "-------�α׷��� ����-------" -BackgroundColor Yellow -ForegroundColor Red

    # ����ڰ� �߸��� �� �Է��Ͽ� while�� ó������ ������ �� ���� ���� 0���� �ʱ�ȭ
	$INGRESS_COUNT = 0

    # ���õ� ���ӽ����̽��� �α׷��� ����� ����Ʈ�� ����
    $global:INGRESSES=(kubectl get ingress -o=name --kubeconfig ${KUBECONFIG_PATH}).replace("ingress.networking.k8s.io/","")
    
	# �α׷��� ��� ���
    foreach ($INGRESS in $global:INGRESSES) {
        $INGRESS_COUNT++;
        Write-Host "${INGRESS_COUNT}: ${INGRESS}"
    }

    Message

    # ������� �ĵ� ������ �Է� �޾� ������ �Ҵ�
    while(1){
        $global:INGRESS_SELECTION = Read-Host "Choose an ingress"
        if($global:INGRESS_SELECTION -ne '') {
            break
        }
    }

    # ����ڰ� q, b, f, r �� �Է��ϴ� ��� 
    if (${global:INGRESS_SELECTION} -eq "q" -or ${global:INGRESS_SELECTION} -eq "b" -or ${global:INGRESS_SELECTION} -eq "f" -or ${global:INGRESS_SELECTION} -eq "r") {
        return Check_Selection_b1_r2 -SELECTION ${global:INGRESS_SELECTION}
    }

    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
    elseif (![int]::TryParse(${global:INGRESS_SELECTION}, [ref]$null) -or [int]${global:INGRESS_SELECTION} -lt 1 -or [int]${global:INGRESS_SELECTION} -gt $($global:INGRESSES.Count) ) {
        Write-Host "Invalid selection. Please enter a number between 1 and $($global:INGRESSES.Count)" -ForegroundColor Red
        return 2
    }

    # �α׷��� ������ ���������� �Ϸ�Ǹ� �����ܰ� ������ ���� "3" �� ���� -> �� �۾� �Լ��� ORDER������ 3 �Ҵ�Ǿ� switch�� ����
    return 3
}

# �ȳ� �޽��� ���
function Message{

    # q�� �Է��ϸ� ��ũ��Ʈ�� ����ȴٴ� �޽��� ���
    Write-Host "Type " -NoNewline
    Write-Host "'q'" -NoNewline -ForegroundColor Magenta
    Write-Host " to quit this script"

    # b�� �Է��ϸ� ���� �ܰ�� �̵��ȴٴ� �޽��� ���
    Write-Host "Type " -NoNewline
    Write-Host "'b'" -NoNewline -ForegroundColor Yellow
    Write-Host " to return to the previous step"

    # f�� �Է��ϸ� ó�� �ܰ�� �̵��ȴٴ� �޽��� ���
    Write-Host "Type " -NoNewline
    Write-Host "'f'" -NoNewline -ForegroundColor Red
    Write-Host " to return to the first step"

    # r�� �Է��ϸ� ���ΰ�ħ �ȴٴ� �޽��� ���
    Write-Host "Type " -NoNewline
    Write-Host "'r'" -NoNewline -ForegroundColor Green
    Write-Host " to refresh this step"
    return
}

# Refresh ����� �ʿ� ���� �� �ȳ� �޽��� ���
function Message_NoRefresh{

    # q�� �Է��ϸ� ��ũ��Ʈ�� ����ȴٴ� �޽��� ���
    Write-Host "Type " -NoNewline
    Write-Host "'q'" -NoNewline -ForegroundColor Magenta
    Write-Host " to quit this script"

    # b�� �Է��ϸ� ���� �ܰ�� �̵��ȴٴ� �޽��� ���
    Write-Host "Type " -NoNewline
    Write-Host "'b'" -NoNewline -ForegroundColor Yellow
    Write-Host " to return to the previous step"

    # f�� �Է��ϸ� ó�� �ܰ�� �̵��ȴٴ� �޽��� ���
    Write-Host "Type " -NoNewline
    Write-Host "'f'" -NoNewline -ForegroundColor Red
    Write-Host " to return to the first step"
    return
}

# Quit �� Back ��ɸ� �ʿ��� ��
function Message_Quit_Back{

    # q�� �Է��ϸ� ��ũ��Ʈ�� ����ȴٴ� �޽��� ���
    Write-Host "Type " -NoNewline
    Write-Host "'q'" -NoNewline -ForegroundColor Magenta
    Write-Host " to quit this script"

    # b�� �Է��ϸ� ���� �ܰ�� �̵��ȴٴ� �޽��� ���
    Write-Host "Type " -NoNewline
    Write-Host "'b'" -NoNewline -ForegroundColor Yellow
    Write-Host " to return to the previous step"
    return
}

# Back�� Order ���� ���� 2�̰� Refresh�� Order ���� ���� 3�� ���
function Check_Selection_b2_r3{
    
    # ������� �Է��� �Ķ���ͷ� �޾ƿ�
    param (
        $SELECTION
    )

    # q�� �Է��� ��� ��ũ��Ʈ ����
    if (${SELECTION} -eq "q") {
        Write-Host "Quit this script" -ForegroundColor Yellow
        exit 0
    }

    # f�� �Է��� ��� ó�� �ܰ�� �̵�
    elseif (${SELECTION} -eq "f"){
        Write-Host "Return to the first step" -ForegroundColor Yellow
        $ORDER = 4
    }

    # b�� �Է��� ��� ���� �ܰ�� �̵�
    elseif (${SELECTION} -eq "b") {
        Write-Host "Return to the previous step" -ForegroundColor Yellow
        $ORDER = 2
    }
                    
    # r�� �Է��� ��� ���ΰ�ħ ����
    elseif (${SELECTION} -eq "r") {
        Write-Host "Refresh this step" -ForegroundColor Yellow
        $ORDER = 3
    }
    
    # ORDER ���� �����Ͽ� ���� �ܰ� ����
    return $ORDER
}

# Back�� Order ���� ���� 1�̰� Refresh�� Order ���� ���� 2�� ���
function Check_Selection_b1_r2{

    # ������� �Է��� �Ķ���ͷ� �޾ƿ�
    param (
        $SELECTION
    )

    # q�� �Է��� ��� ��ũ��Ʈ ����
    if (${SELECTION} -eq "q") {
        Write-Host "Quit this script" -ForegroundColor Yellow
        exit 0
    }

    # f�� �Է��� ��� ó�� �ܰ�� �̵�
    elseif (${SELECTION} -eq "f"){
        Write-Host "Return to the first step" -ForegroundColor Yellow
        $ORDER = 4
    }

    # b�� �Է��� ��� ���� �ܰ�� �̵�
    elseif (${SELECTION} -eq "b") {
        Write-Host "Return to the previous step" -ForegroundColor Yellow
        $ORDER = 1
    }
                    
    # r�� �Է��� ��� ���ΰ�ħ ����
    elseif (${SELECTION} -eq "r") {
        Write-Host "Refresh this step" -ForegroundColor Yellow
        $ORDER = 2
    }

    # ORDER ���� �����Ͽ� ���� �ܰ� ����
    return $ORDER
}

# Back�� Order ���� ���� 3�̰� Refresh ����� �ʿ� ���� ���
function Check_Selection_b3_rNo{
    
    # ������� �Է��� �Ķ���ͷ� �޾ƿ�
    param (
        $SELECTION
    )

    # q�� �Է��� ��� ��ũ��Ʈ ����
    if (${SELECTION} -eq "q") {
        Write-Host "Quit this script" -ForegroundColor Yellow
        exit 0
    }

    # f�� �Է��� ��� ó�� �ܰ�� �̵�
    elseif (${SELECTION} -eq "f"){
        Write-Host "Return to the first step" -ForegroundColor Yellow
        $ORDER = 4
    }

    # b�� �Է��� ��� ���� �ܰ�� �̵�
    elseif (${SELECTION} -eq "b") {
        Write-Host "Return to the previous step" -ForegroundColor Yellow
        $ORDER = 3
    }
    
    # ORDER ���� �����Ͽ� ���� �ܰ� ����
    return $ORDER
}

# 4 Jeus Admin �۾� ����
function Number0_4 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect
                continue
            }

            # �ĵ� ����
            2 {
                $ORDER = PodSelect
                continue
            }
            # JEUS_ADMIN �۾� ����
            3 {

                # "Jeus Admin ��ɾ� ����" �ܰ� �˸� �޽�ġ ���
                Write-Host "-------Jeus Admin ��ɾ� ���� �۾� ����-------" -BackgroundColor Yellow -ForegroundColor Red

                # ����ڿ��� �۾� ��� ���
                foreach ($CHOICE in $CHOICES_JEUS_ADMIN.GetEnumerator()) {
                Write-Host "$($CHOICE.Key) $($CHOICE.Value)"
                }

                # ��ũ��Ʈ �ܰ� �̵� ���� ���
                Message_NoRefresh

                # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                while(1){
                    $JOB = Read-Host "Choose a container"
                    if($JOB -ne '') {
                        break
                    }
                }

                # ����� ���� ���� Ȯ��
                if (${JOB} -eq "q" -or ${JOB} -eq "f" -or ${JOB} -eq "b"){
                    $ORDER = Check_Selection_b2_r3 -Selection ${JOB}
                    continue
                }

                # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� �ȳ� �޽��� ��� �� SelectJob �ٽ� ����
                elseif (![int]::TryParse($JOB, [ref]$null) -or [int]${JOB} -lt 1 -or [int]${JOB} -gt $($CHOICES_JEUS_ADMIN.Count) ) {
                    Write-Host "Invalid selection. Please enter a number between 1 and $($CHOICES_JEUS_ADMIN.Count)" -ForegroundColor Red
                    continue
                }

                # Jeusadmin ����
                elseif($JOB -eq 1){
                    $ORDER = 6
                    continue
                }

                # Jeus Corelated server ��� ��ȸ
                elseif($JOB -eq 2){
                    $ORDER = 7
                    continue
                }

                # Jeus ��� ���� ��� Ȯ��
                elseif($JOB -eq 3){
                    $ORDER = 8
                    continue
                }

                # Server information ��ȸ
                elseif($JOB -eq 4){
                    $ORDER = 9
                    continue
                }

                # list-servers Ȯ��
                elseif($JOB -eq 5){
                    $ORDER = 10
                    continue
                }
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return
            }

            # �ڷΰ��� ����
            5{
                return 4
            }

            # JEUS_ADMIN ����
            6 {

                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){

                    try {
                        # JEUS Admin ���� ��Ʈ ���� �Ҵ�
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # �ȳ� �޽��� ���
                        Write-Host -NoNewline "Access to jeusadmin of "
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green
                        
                        # ���õ� �ĵ忡�� jeusadmin ����          
                        Start-Process -NoNewWindow -Wait -FilePath 'kubectl' -ArgumentList "exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c `"/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT}`""

                        # ���� �ȳ� �޽��� ���
                        Write-Host "`nTerminating session..."
                    }
                    catch {
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �ĵ�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # �۾� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 3
                    continue
                }

                # �ĵ峻 �����̳ʰ� 2�� �̻��� ���
                else {
                    
                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message_NoRefresh

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break 
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b"){
                        $ORDER = Check_Selection_b3_rNo -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    try {
                        # JEUS Admin ���� ��Ʈ ���� �Ҵ�
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # �ȳ� �޽��� ���
                        Write-Host -NoNewline "Access to jeusadmin of "
                        Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green
                        
                        # ���õ� �ĵ忡�� jeusadmin ����
                        Start-Process -NoNewWindow -Wait -FilePath 'kubectl' -ArgumentList "exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c `"/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT}`""
                        # kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT}" | Out-Host 

                        # ���� �ȳ� �޽��� ���
                        Write-Host "Terminating session..."
                    }
                    catch {
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �����̳�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }
                    
                    # �۾� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 3
                    continue
                }
            }

            # Jeus Corelated server ��� ��ȸ
            7 {

                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){

                    try {
                        # JEUS Admin ���� ��Ʈ ���� �Ҵ�
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # �ȳ� �޽��� ���
                        Write-Host -NoNewline "Checking list of corelated-servers of "
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                        # ���õ� �ĵ忡�� list-corelated-servers Ȯ��
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'list-corelated-servers'" | Out-Host
                        
                        # ���� �ȳ� �޽��� ���
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �ĵ�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # �۾� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 3
                    continue
                }
                else {
                    
                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message_NoRefresh

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b"){
                        $ORDER = Check_Selection_b3_rNo -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                    
                    try {
                        # JEUS Admin ���� ��Ʈ ���� �Ҵ�
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # �ȳ� �޽��� ���
                        Write-Host -NoNewline "Checking list of corelated-servers of "
                        Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green
                        
                        # ���õ� �ĵ忡�� list-corelated-servers Ȯ��
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'list-corelated-servers'" | Out-Host
                        
                        # ���� �ȳ� �޽��� ���
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �����̳�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # �۾� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 3
                    continue
                }
            }

            # Jeus ��� ���� ��� Ȯ��
            8 {

                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){

                    try {
                        # JEUS Admin ���� ��Ʈ ���� �Ҵ�
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # �ȳ� �޽��� ���
                        Write-Host -NoNewline "Checking list of show-web-statistics of "
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                        # ���õ� �ĵ忡�� Jeus ��� ���� ��� Ȯ��
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'show-web-statistics -server $($PODS[$POD_SELECTION-1])'" | Out-Default
                        
                        # ���� �ȳ� �޽��� ���
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �ĵ�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # �۾� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 3
                    continue
                }
                else {
                    
                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message_NoRefresh

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b"){
                        $ORDER = Check_Selection_b3_rNo -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                    
                    try {
                        # JEUS Admin ���� ��Ʈ ���� �Ҵ�
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # �ȳ� �޽��� ���
                        Write-Host -NoNewline "Checking list of show-web-statistics of of "
                        Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green
                        
                        # ���õ� �ĵ忡�� Jeus ��� ���� ��� Ȯ��
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'show-web-statistics -server $($PODS[$POD_SELECTION-1])'" | Out-Default
                        
                        # ���� �ȳ� �޽��� ���
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �����̳�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # �۾� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 3
                    continue
                }
            }

            # Server information ��ȸ
            9 {

                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){

                    try {
                        # JEUS Admin ���� ��Ʈ ���� �Ҵ�
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # �ȳ� �޽��� ���
                        Write-Host -NoNewline "Checking Server information of "
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                        # ���õ� �ĵ忡�� Server information Ȯ��
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'si'" | Out-Default
                        
                        # ���� �ȳ� �޽��� ���
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �ĵ�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # �۾� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 3
                    continue
                }
                else {
                    
                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message_NoRefresh

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b"){
                        $ORDER = Check_Selection_b3_rNo -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                    
                    try {
                        # JEUS Admin ���� ��Ʈ ���� �Ҵ�
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # �ȳ� �޽��� ���
                        Write-Host -NoNewline "Checking Server information of "
                        Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green
                        
                        # ���õ� �ĵ忡�� Server information Ȯ��
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'si'" | Out-Default
                        
                        # ���� �ȳ� �޽��� ���
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �����̳�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # �۾� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 3
                    continue
                }
            }

            # list-servers ��ȸ
            10 {

                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){

                    try {
                        # JEUS Admin ���� ��Ʈ ���� �Ҵ�
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # �ȳ� �޽��� ���
                        Write-Host -NoNewline "Checking list-servers of "
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                        # ���õ� �ĵ忡�� list-servers Ȯ��
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'list-servers'" | Out-Default
                        
                        # ���� �ȳ� �޽��� ���
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �ĵ�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # �۾� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 3
                    continue
                }
                else {
                    
                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message_NoRefresh

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b"){
                        $ORDER = Check_Selection_b3_rNo -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                    
                    try {
                        # JEUS Admin ���� ��Ʈ ���� �Ҵ�
                        Write-Host "Now Checking Jeus Admin Server Port..."
                        $JEUS_ADMIN_PORT = (kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- cat /home/tmax/jeus8/domains/jeus_domain/servers/$($PODS[$POD_SELECTION-1])/nodemanager/$($PODS[$POD_SELECTION-1]).address).split(":")[1]  2> $null
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }
                        Write-Host "Finished checking Jeus Admin Port"
                        # �ȳ� �޽��� ���
                        Write-Host -NoNewline "Checking list-servers of "
                        Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green
                        
                        # ���õ� �ĵ忡�� list-servers Ȯ��
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c "/home/tmax/jeus8/bin/jeusadmin -u jeus -f /home/tmax/scripts/jeusEncode -cachelogin -verbose -port ${JEUS_ADMIN_PORT} 'list-servers'" | Out-Default
                        
                        # ���� �ȳ� �޽��� ���
                        Write-Host "`nTerminating session..."
                    }
                    catch {

                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �����̳�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # �۾� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 3
                    continue
                }
            }
        }        
    }
}

# 0-5. �ĵ� �� ����
function Number0_5 {
    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect
                continue
            }

            # �ĵ� ����
            2 {
                $ORDER = PodSelect
                continue
            }

            # �����̳� ���� & �۾�
            3 {
                
                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){

                    # �ĵ� ���� �޽��� ���
                    Write-Host -NoNewline "Connect to "
                    Write-Host "$($PODS[$POD_SELECTION-1])e" -ForegroundColor Green

                    # ���õ� �ĵ�/�����̳� ����
                    try{
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- /bin/bash 2> $null
                        if($LASTEXITCODE -eq 1){
                            throw "error �߻�"
                        }
                    }
                    catch{
                        Write-Host "���õ� �ĵ尡 �̹� ���ŵǾ��ų� Ŭ�����Ϳ� api��û�� ���� �� �����ϴ�. ������ ��ġ �� �õ����ּ���."
                    }
		            
                    # �ĵ� ���� ���� �� �ĵ� ���� �ܰ���� �����
                    $ORDER = 2
                    continue
                }
                else {
                    
                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red

                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }
                    
                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # �ĵ� ���� �޽��� ���
                    Write-Host -NoNewline "Connect to "
                    Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor Green

                    # ���õ� �ĵ�/�����̳� ����
                    try{
                        kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- /bin/bash 2> $null
                        if($LASTEXITCODE -eq 1){
                            throw "error �߻�"
                        }
                    }
                    catch{
                        Write-Host "���õ� �ĵ尡 �̹� ���ŵǾ��ų� Ŭ�����Ϳ� api��û�� ���� �� �����ϴ�. ������ ��ġ �� �ٽ� �õ����ּ���."
                    }
                    
                    # �ĵ� ���� ���� �� �ĵ� ���� �ܰ���� �����
                    $ORDER = 2
                    continue
                }
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return
            }
        }        
    }
}

# 0-6. Network Policy �ڵ� ����(SKE ������ ���̵�)
function Number0_6 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch (${ORDER}) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect
                continue
            }

            # ��Ʈ��ũ ������ ����
            2 {
                # �ӽ����� ���� �� �ߺ� ������ ���ϱ� ���� �ð��� ������ �Ҵ��Ͽ� �ش� ���� ���� �̸��� �ٿ� ���
                $TIME = Get-Date -Format "yyyy/MM/dd"

                # "Network Policy ���� ��" �޽��� ���
                Write-Host "Creating Network Policies." -NoNewline -ForegroundColor Yellow
                Write-Host "..."

                # Ingress Controller�� Name�� ������ ����
                $INGRESS_CONTROLLERS = (kubectl get deployment -o name --kubeconfig ${KUBECONFIG_PATH} -l app=ingress-controller).replace("deployment.apps/","")
                
                # Release Name�� ������ ���� -> �������� Ingress Controller �� ������ ��� �������� NetworkPolicy ������ �ʿ��ϱ� ����
                $RELEASES = @()
                foreach($INGRESS_CONTROLLER in $INGRESS_CONTROLLERS) {
                    $TEMP = kubectl get deployment ${INGRESS_CONTROLLER} --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.metadata.labels.release}"
                    $RELEASES += $TEMP
                }

                # Network Policy ������ ���� �ӽ� YAML���� ����
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
                # �ӽ����� ���� �� Manifest ���� �߰�
                Set-Content -Path "./networkpolicy_temp_${TIME}.yaml" -Value $NETWORKPOLICY_YAML

                # �������� Ingress Controller �� ������ ��� �������� NetworkPolicy �����ϱ� ���� foreach�� ���
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
                    # Manifest ���� �ӽ����Ͽ� �߰�
                    Add-Content -Path "./networkpolicy_temp_${TIME}.yaml" -Value $NETWORKPOLICY_INGRESS_YAML
                }

                # ����ڿ��� ������ Network policy manifest ���
                kubectl apply --kubeconfig=${KUBECONFIG_PATH} --dry-run=client -o yaml -f ./networkpolicy_temp_${TIME}.yaml

                # "���� ���� ����" �ܰ� �˸� �޽�ġ ���
                Write-Host "-------���� ���� �Է�-------" -BackgroundColor Yellow -ForegroundColor Red

                # Network policy �����ϱ� �� ����ڿ��� Ȯ�� ���� ��û
                Write-Host "Please confirm the YAML`nAre you sure to create network policies?(Y/N)" -ForegroundColor Yellow

                # ���� ������ ������ ����ڿ��� �Է��� ���� ����
                while(1) {
                    $SELECT = Read-Host " "
                    # N�� �Է��� ��� ���� �������� ����
                    if($SELECT -eq 'N'){
                        break
                    }
                    # Y�� �Է��� ��� ������ ��Ʈ��ũ ������ ����
                    elseif($SELECT -eq 'Y') {
                        kubectl apply --kubeconfig=${KUBECONFIG_PATH} -f ./networkpolicy_temp_${TIME}.yaml
                        break
                    }
                    # ������ �Է��ϸ� �ٽ� �Է� �޵��� ��
                    elseif($SELECT -eq '') {
                        continue
                    }
                    # �߸��� ���� �Է��� ��� �˸� �޽��� ��� �� �ٽ� �Է� ����
                    else {
                        Write-Host "Please enter correct value(Y/N)" -ForegroundColor Red
                        continue
                    }
                }

                # �ӽ����� ����
                Remove-Item ./networkpolicy_temp_${TIME}.yaml

                # Network Policy ���� �Ϸ� �� ���ӽ����̽� ���� �ܰ�� ���ư��� ���� ORDER������ 1�� �Ҵ� �� continue ����
                $ORDER = 1
                continue
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return
            }
        }        
    }
}

# 0-7. ���� ���� (�����̳� <-> ���� PC)
function Number0_7 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect
                continue
            }

            # �ĵ� ����
            2 {
                $ORDER = PodSelect
                continue
            }

            # �����̳� ���� & �۾�
            3 {

                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){
                    
                    # "���� �ɼ� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------���� �ɼ� ����-------" -BackgroundColor Yellow -ForegroundColor Red

                    # ���� �ɼ� ���� (Cotainer to Local PC / Local PC to Container)
                    Write-Host "Select Copy Option`n1: Container to local`n2: Local to container"

                    Message_NoRefresh

                    # ������� ������ �Է� ����
                    while(1){
                        $COPY_OPTION = Read-Host "Choose an option"
                        if($COPY_OPTION -ne ''){
                            break
                        }
                    }

                    # q�� �Է��� ��� ��ũ��Ʈ ����
                    if (${COPY_OPTION} -eq "q" -or ${COPY_OPTION} -eq "f" -or ${COPY_OPTION} -eq "b") {
                        $ORDER = Check_Selection_b2_r3 -SELECTION ${COPY_OPTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${COPY_OPTION}, [ref]$null) -or [int]${COPY_OPTION} -lt 1 -or [int]${COPY_OPTION} -gt 2 ) {
                        Write-Host "Invalid selection. Please enter a number 1 or 2" -ForegroundColor Red
                        continue
                    }

                    # Cotainer to Local PC
                    elseif( $COPY_OPTION -eq 1 ) {
                        
                        # "�ҽ����� ���(�����̳�) �Է�" �ܰ� �˸� �޽�ġ ���
                        Write-Host "-------�ҽ����� ���(�����̳�) �Է�-------" -BackgroundColor Yellow -ForegroundColor Red

                        # �ҽ����� ���(�����̳�) ����
                        While(1){
                            $SRC = Read-Host "Type path of source file."
                            if($SRC -ne '') {
                                break
                            }
                        }
                        $SOURCE = $($PODS[$POD_SELECTION-1])+":"+ ${SRC}

                        # "���� ���(����) �Է�" �ܰ� �˸� �޽�ġ ���
                        Write-Host "-------���� ���(����) �Է�-------" -BackgroundColor Yellow -ForegroundColor Red

                        # ���� ���(����) ����
                        While(1){
                            $DESTINATION = Read-Host "Type path of destination file."
                            if($DESTINATION -ne ''){
                                break
                            }
                        }

                        # �α� ����
                        kubectl cp ${SOURCE} ${DESTINATION} --kubeconfig ${KUBECONFIG_PATH}
                    }

                    # Local PC to Container
                    elseif($COPY_OPTION -eq 2) {

                        # "�ҽ����� ���(����) �Է�" �ܰ� �˸� �޽�ġ ���
                        Write-Host "-------�ҽ����� ���(�����̳�) �Է�-------" -BackgroundColor Yellow -ForegroundColor Red

                        # �ҽ����� ���(����) ����
                        While(1){
                            $SOURCE = Read-Host "Type path of source file."
                            if($SOURCE -ne ''){
                                break
                            }
                        }
                        
                        # "���� ���(�����̳�) �Է�" �ܰ� �˸� �޽�ġ ���
                        Write-Host "-------���� ���(�����̳�) �Է�-------" -BackgroundColor Yellow -ForegroundColor Red

                        # ���� ���(�����̳�) ����
                        While(1){
                            $DEST = Read-Host "Type path of destination file."
                            if($DEST -ne ''){
                                break
                            }
                        }
                        $DESTINATION = $($PODS[$POD_SELECTION-1])+":"+ ${DEST}

                        # �α� ����
                        kubectl cp ${SOURCE} ${DESTINATION} --kubeconfig ${KUBECONFIG_PATH}
                    }

                    # �α� ���� �Ϸ� �� ORDER ������ 2�� �Ҵ��Ͽ� �ĵ� ���� ���� �ٽ� ����
                    $ORDER = 2
                    continue
                }

                # �����̳ʰ� 2�� �̻��� ���
                else {
                    
                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0
                    
                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                    
                    # "���� �ɼ� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------���� �ɼ� ����-------" -BackgroundColor Yellow -ForegroundColor Red

                    # ���� �ɼ� ���� (Cotainer to Local PC / Local PC to Container)
                    Write-Host "Select Copy Option`n1.Container to local`n2.Local to container"

                    Message_NoRefresh
                    
                    # ������� �Է��� ������ �Ҵ�
                    While(1){
                        $COPY_OPTION = Read-Host "Choose an option"
                        if($COPY_OPTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${COPY_OPTION} -eq "q" -or ${COPY_OPTION} -eq "f" -or ${COPY_OPTION} -eq "b"){
                        $ORDER = Check_Selection_b3_rNo -Selection ${COPY_OPTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${COPY_OPTION}, [ref]$null) -or [int]${COPY_OPTION} -lt 1 -or [int]${COPY_OPTION} -gt 2 ) {
                        Write-Host "Invalid selection. Please enter a number 1 or 2" -ForegroundColor Red
                        continue
                    }
                    

                    # Cotainer to Local PC
                    elseif( $COPY_OPTION -eq 1 ) {
                        
                        # "�ҽ����� ���(�����̳�) �Է�" �ܰ� �˸� �޽�ġ ���
                        Write-Host "-------�ҽ����� ���(�����̳�) �Է�-------" -BackgroundColor Yellow -ForegroundColor Red

                        # �ҽ����� ���(�����̳�) ����
                        while(1){
                            $SRC = Read-Host "Type path of source file."
                            if($SRC -ne '') {
                                break
                            }
                        }
                        $SOURCE = $($PODS[$POD_SELECTION-1])+":"+ ${SRC}
                        
                        # "���� ���(����) �Է�" �ܰ� �˸� �޽�ġ ���
                        Write-Host "-------���� ���(����) �Է�-------" -BackgroundColor Yellow -ForegroundColor Red
                        
                        # ���� ���(����) ����
                        while(1){
                            $DESTINATION = Read-Host "Type path of destination file."
                            if($DESTINATION -ne '') {
                                break
                            }
                        }
                        # �α� ����
                        kubectl cp -c $($CONTAINERS[$CONTAINER_SELECTION-1]) ${SOURCE} ${DESTINATION} --kubeconfig ${KUBECONFIG_PATH}
                    }

                    # Local PC to Container
                    elseif($COPY_OPTION -eq 2) {
                        
                        # "�ҽ����� ���(����) �Է�" �ܰ� �˸� �޽�ġ ���
                        Write-Host "-------�ҽ����� ���(����) �Է�-------" -BackgroundColor Yellow -ForegroundColor Red
                        
                        # �ҽ����� ���(����) ����
                        while(1) {
                            $SOURCE = Read-Host "Type path of source file."
                            if($SOURCE -ne ''){
                                break
                            }
                        }
                                                
                        # "���� ���(�����̳�) �Է�" �ܰ� �˸� �޽�ġ ���
                        Write-Host "-------���� ���(�����̳�) �Է�-------" -BackgroundColor Yellow -ForegroundColor Red

                        # ���� ���(�����̳�) ����
                        while(1){
                            $DEST = Read-Host "Type path of destination file."
                            if($DEST -ne ''){
                                break
                            }
                        }
                        $DESTINATION = $($PODS[$POD_SELECTION-1])+":"+ ${DEST}

                        # �α� ����
                        kubectl cp -c $($CONTAINERS[$CONTAINER_SELECTION-1]) ${SOURCE} ${DESTINATION} --kubeconfig ${KUBECONFIG_PATH}
                    }

                    # �α� ���� �Ϸ� �� ORDER ������ 2�� �Ҵ��Ͽ� �ĵ� ���� ���� �ٽ� ����
                    $ORDER = 2
                    continue
                }
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return
            }

        }        
    }
}

# 0-8. DB Ŀ�ؼ� �׽�Ʈ
function Number0_8 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect
                continue
            }

            # �ĵ� ����
            2 {''
                $ORDER = PodSelect
                continue
            }

            # �����̳� ���� & �۾�
            3 {

                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){
                    
                    # "DB IP �Է�" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------DB IP �Է�-------" -BackgroundColor Yellow -ForegroundColor Red

                    # ����ڿ��� DB IP �� �Է� �޾� ������ �Ҵ�
                    while(1){
                        $DB_IP = Read-Host "Type DB IP: "
                        if($DB_IP -ne ''){
                            break
                        }
                    }

                    # "DB Port �Է�" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------DB Port �Է�-------" -BackgroundColor Yellow -ForegroundColor Red

                    # ����ڿ��� DB Port �� �Է� �޾� ������ �Ҵ�
                    while(1){
                        $DB_PORT = Read-Host "Type DB Port: "
                        if ($DB_PORT -ne ''){
                            break
                        }
                    }
                    

                    # ���� �׽�Ʈ ���̶�� �޽��� ���
                    Write-Host -NoNewline "Connecting test from "
                    Write-Host "$($PODS[$POD_SELECTION-1]) to ${DB_IP}:${DB_PORT}" -ForegroundColor green

                    # ���õ� �ĵ忡�� DB Connection Test ����
		            kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- curl -v telnet://${DB_IP}:${DB_PORT}

                    # Ŀ�ؼ� �׽�Ʈ �Ϸ� �� ORDER ������ 2�� �Ҵ��Ͽ� �ĵ� ���� ���� �ٽ� ����
                    $ORDER = 2
                    continue
                }

                # �����̳ʰ� 2�� �̻��� ���
                else {
                                        
                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # "DB IP �Է�" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------DB IP �Է�-------" -BackgroundColor Yellow -ForegroundColor Red

                    # ����ڿ��� DB IP �� �Է� �޾� ������ �Ҵ��
                    while(1){
                        $DB_IP = Read-Host "Type DB IP: "
                        if($DB_IP -ne ''){
                            break
                        }
                    }

                    # "DB Port �Է�" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------DB Port �Է�-------" -BackgroundColor Yellow -ForegroundColor Red

                    # ����ڿ��� DB Port �� �Է� �޾� ������ �Ҵ�
                    While(1) {
                        $DB_PORT = Read-Host "Type DB Port: "
                        if($DB_PORT -ne ''){
                            break
                        }
                    }
                    # ���� �׽�Ʈ ���̶�� �޽��� ���
                    Write-Host -NoNewline "Connecting test from "
                    Write-Host "$($PODS[$POD_SELECTION-1])/$($CONTAINERS[$CONTAINER_SELECTION-1]) to ${DB_IP}:${DB_PORT}" -ForegroundColor green
                    
                    # ���õ� �ĵ忡�� DB Connection Test ����
		            kubectl exec -it -c $($CONTAINERS[$CONTAINER_SELECTION-1]) $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- curl -v telnet://${DB_IP}:${DB_PORT}

                    # Ŀ�ؼ� �׽�Ʈ �Ϸ� �� ORDER ������ 2�� �Ҵ��Ͽ� �ĵ� ���� ���� �ٽ� ����
                    $ORDER = 2
                    continue
                    
                }
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return
            }

        }        
    }
}

# 1-1 ��� ���ӽ����̽��� POD CPU/Memory ���� ���� ��ȸ
function Number1_1 {

    # sum, --containers �ɼ� �ִ� ���
    try {

        # Kubectl top�� --sum, --containers �ɼ��� ���ԵǾ� �ִ��� Ȯ���Ѵٴ� �޽��� ���
        Write-Host "Checking 'Kubectl top' includes " -NoNewline; Write-Host "'--sum'" -NoNewline -ForegroundColor Green; Write-Host " and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Green; Write-Host " options...";
        
        # Kubectl ������ ���� �ɼ��� ���� ��쿡 ���� �߻���Ű�� ���� ����
        kubectl top pods --kubeconfig $KUBECONFIG\$($KUBECONFIG_FILES[0]) --containers --sum > $null 2>&1
        if ($LASTEXITCODE) {
            throw "$LASTEXITCODE"
        }

        # kubectl top�� --sum�� --containers �ɼ��� ���ԵǾ� �ִٴ� �޽��� ���
        Write-Host "Kubectl top includes " -NoNewline; Write-Host "'--sum' " -NoNewline -ForegroundColor Green; Write-Host "and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Green; Write-Host " options";

        # �۾� �Ϸ� �� ���� ������ ���� ���� �ʱ�ȭ
        [int]$COUNT = 0

        # POD CPU/Memory ���� ���� ��ȸ
        foreach ($KUBECONIFG_FILE in $KUBECONFIG_FILES) {
            Write-Host -NoNewline "------------------------------------------------"
            Write-Host -NoNewline "$(${NAMESPACE_LIST}[$COUNT++])".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue
            Write-Host "------------------------------------------------"
            kubectl top pods --kubeconfig $KUBECONFIG\$KUBECONIFG_FILE --containers --sum

        }
    }

    # sum, --containers �ɼ� ���� ���
    catch{
        
        # kubectl top�� --sum�� --containers �ɼ��� ���ԵǾ� ���� �ʴٴ� �޽��� ���
        Write-Host "'--sum' " -NoNewline -ForegroundColor Red; Write-Host "and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Red; Write-Host " options does not exist";

        # �۾� �Ϸ� �� ���� ������ ���� ���� �ʱ�ȭ
        [int]$COUNT = 0
        
        # POD CPU/Memory ���� ���� ��ȸ
        foreach ($KUBECONIFG_FILE in $KUBECONFIG_FILES) {
            Write-Host -NoNewline "------------------------------------------------"
            Write-Host -NoNewline "$(${NAMESPACE_LIST}[$COUNT++])".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue
            Write-Host "------------------------------------------------"
            kubectl top pods --kubeconfig $KUBECONFIG\$KUBECONIFG_FILE
        }
    }
}

# 1-2 Ư�� ���ӽ����̽��� Pod CPU/Memory ���� ���� ��ȸ
function Number1_2 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # CPU/Memory ���� ��ȸ
            2 {

                # sum, --containers �ɼ� �ִ� ���
                try {
                    
                    # Kubectl top�� --sum, --containers �ɼ��� ���ԵǾ� �ִ��� Ȯ���Ѵٴ� �޽��� ���
                    Write-Host "Checking 'Kubectl top' includes " -NoNewline; Write-Host "'--sum'" -NoNewline -ForegroundColor Green; Write-Host " and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Green; Write-Host " options...";
                    
                    # Kubectl ������ ���� �ɼ��� ���� ��쿡 ���� �߻���Ű�� ���� ����
                    kubectl top pods --kubeconfig $KUBECONFIG\$($KUBECONFIG_FILES[0]) --containers --sum > $null 2>&1
                    if ($LASTEXITCODE) {
                        throw "$LASTEXITCODE"
                    }

                    # kubectl top�� --sum�� --containers �ɼ��� ���ԵǾ� �ִٴ� �޽��� ���
                    Write-Host "Kubectl top includes " -NoNewline; Write-Host "'--sum' " -NoNewline -ForegroundColor Green; Write-Host "and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Green; Write-Host " options";

                    # ������ ���ӽ����̽��� ���� ���
                    Write-Host -NoNewline "------------------------------------------------"; Write-Host -NoNewline "$NAMESPACE".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue; Write-Host "------------------------------------------------";
                    kubectl top pods --kubeconfig ${KUBECONFIG_PATH} --containers --sum | Out-Host
                    Write-Host "------------------------------------------------------------------------------------------------" -NoNewline; Write-Host ("-" * ($NAMESPACE).Length);

                    # ��� �Ϸ� �� ���ӽ����̽� �������� ���ư��� ���� $ORDER�� 1�� �Ҵ��ϰ� while�� �ٽ� ����
                    $ORDER = 1
                    continue
                }

                # sum, --containers �ɼ� ���� ���
                catch{
                    
                    # kubectl top�� --sum�� --containers �ɼ��� ���ԵǾ� ���� �ʴٴ� �޽��� ���
                    Write-Host "'--sum' " -NoNewline -ForegroundColor Red; Write-Host "and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Red; Write-Host " options does not exist";

                    # ������ ���ӽ����̽��� ���� ���
                    Write-Host -NoNewline "------------------------------------------------"; Write-Host -NoNewline "$NAMESPACE".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue; Write-Host "------------------------------------------------";
                    kubectl top pods --kubeconfig ${KUBECONFIG_PATH} | Out-Host
                    Write-Host "------------------------------------------------------------------------------------------------" -NoNewline; Write-Host ("-" * ($NAMESPACE).Length);

                    # ��� �Ϸ� �� ���ӽ����̽� �������� ���ư��� ���� $ORDER�� 1�� �Ҵ��ϰ� while�� �ٽ� ����
                    $ORDER = 1
                    continue
                }
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return 0
            }

            # �ڷΰ��� ����
            5{
                return 1
            }

        }        
    }
}

# 1-3 CPU, Memory �ǽð� ����͸�
function Number1_3 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # CPU/Memory ���� ��ȸ
            2 {

                # sum, --containers �ɼ� �ִ� ���
                try {
                    
                    # Kubectl top�� --sum, --containers �ɼ��� ���ԵǾ� �ִ��� Ȯ���Ѵٴ� �޽��� ���
                    Write-Host "Checking 'Kubectl top' includes " -NoNewline; Write-Host "'--sum'" -NoNewline -ForegroundColor Green; Write-Host " and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Green; Write-Host " options...";
                    
                    # Kubectl ������ ���� �ɼ��� ���� ��쿡 ���� �߻���Ű�� ���� ����
                    kubectl top pods --kubeconfig $KUBECONFIG\$($KUBECONFIG_FILES[0]) --containers --sum --use-protocol-buffers=true > $null 2>&1
                    if ($LASTEXITCODE) {
                        throw "$LASTEXITCODE"
                    }

                    # kubectl top�� --sum�� --containers �ɼ��� ���ԵǾ� �ִٴ� �޽��� ���
                    Write-Host "Kubectl top includes " -NoNewline; Write-Host "'--sum' " -NoNewline -ForegroundColor Green; Write-Host "and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Green; Write-Host " options";

                    # ȣ��Ʈ ����� ���� -> Ŀ�� ��ġ�� �ֻ������ �����
                    Clear-Host

                    # ���� Ŀ�� ��ġ(�ֻ��)�� ������ ����
                    $CURRENTCURSORPOSITION = $Host.UI.RawUI.CursorPosition

                    # ������ ���ӽ����̽��� ���� ���
                    while(1){

                        $DATE = (Get-Date -Format 'yyyy-MM-dd HH:mm.ss.fff')
                        
                        # kubectl ������� ������ �Ҵ�
                        $RESULT = $(kubectl top pods --kubeconfig ${KUBECONFIG_PATH} --containers --sum --use-protocol-buffers=true)

                        # ���� Ŀ�� ��ġ(�ֻ��) ������ �ֻ������ ����
                        $Host.UI.RawUI.CursorPosition = $CURRENTCURSORPOSITION
                        
                        # ����� ���                        
                        Write-Host "${DATE}"
                        Write-Host -NoNewline "------------------------------------------------"; Write-Host -NoNewline "$NAMESPACE".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue; Write-Host "------------------------------------------------";
                        $RESULT -split '\r?\n' | ForEach-Object { Write-Host "$_" }
                        Write-Host "------------------------------------------------------------------------------------------------" -NoNewline; Write-Host ("-" * ($NAMESPACE).Length);

                        # ����� �Է¿� ���� �ȳ��� ���
                        Write-Host "Press " -NoNewline; Write-Host "'q'" -NoNewline -ForegroundColor Yellow; Write-Host " to quit this step.";
                        Write-Host "Press " -NoNewline; Write-Host "'c'" -NoNewline -ForegroundColor Yellow; Write-Host " to clear this terminal." -NoNewline;

                        # ����ڰ� �Է¿� ���� ������ ����
                        if ([System.Console]::KeyAvailable) {
                            $KEY = [System.Console]::ReadKey($true)

                            # q�� �Է��ϸ� while�� ����
                            if ($KEY.KeyChar -eq 'q' -or $KEY.KeyChar -eq 'Q') {
                                Write-Host "`nQuit this step"
                                break
                            }

                            # c�� �Է��ϸ� clear ����
                            elseif ($KEY.KeyChar -eq 'c' -or $KEY.KeyChar -eq 'C') {
                                Write-Host "`nClear this terminal"
                                Start-Sleep -Milliseconds 500
                                Clear-Host
                                continue
                            }
                        }
                    }
                    
                    # ��� �Ϸ� �� ���ӽ����̽� �������� ���ư��� ���� $ORDER�� 1�� �Ҵ��ϰ� while�� �ٽ� ����
                    $ORDER = 1
                    continue
                }

                # sum, --containers �ɼ� ���� ���
                catch{
                    
                    # kubectl top�� --sum�� --containers �ɼ��� ���ԵǾ� ���� �ʴٴ� �޽��� ���
                    Write-Host "'--sum' " -NoNewline -ForegroundColor Red; Write-Host "and " -NoNewline; Write-Host "'--containers'" -NoNewline -ForegroundColor Red; Write-Host " options does not exist";

                    # ȣ��Ʈ ����� ���� -> Ŀ�� ��ġ�� �ֻ������ �����
                    Clear-Host

                    # ���� Ŀ�� ��ġ(�ֻ��)�� ������ ����
                    $CURRENTCURSORPOSITION = $Host.UI.RawUI.CursorPosition

                    # ������ ���ӽ����̽��� ���� ���
                    while(1){

                        $DATE = (Get-Date -Format 'yyyy-MM-dd HH:mm.fff')

                        # kubectl ������� ������ �Ҵ�
                        $RESULT = $(kubectl top pods --kubeconfig ${KUBECONFIG_PATH})

                        # ���� Ŀ�� ��ġ(�ֻ��) ������ �ֻ������ ����
                        $Host.UI.RawUI.CursorPosition = $CURRENTCURSORPOSITION
                        
                        # ����� ���
                        Write-Host "${DATE}"
                        Write-Host -NoNewline "------------------------------------------------"; Write-Host -NoNewline "$NAMESPACE".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue; Write-Host "------------------------------------------------";
                        $RESULT -split '\r?\n' | ForEach-Object { Write-Host "$_" }
                        Write-Host "------------------------------------------------------------------------------------------------" -NoNewline; Write-Host ("-" * ($NAMESPACE).Length);

                        # ����� �Է¿� ���� �ȳ��� ���
                        Write-Host "Press " -NoNewline; Write-Host "'q'" -NoNewline -ForegroundColor Yellow; Write-Host " to quit this step.";
                        Write-Host "Press " -NoNewline; Write-Host "'c'" -NoNewline -ForegroundColor Yellow; Write-Host " to clear this terminal." -NoNewline;

                        # ����ڰ� �Է¿� ���� ������ ����
                        if ([System.Console]::KeyAvailable) {
                            $KEY = [System.Console]::ReadKey($true)

                            # q�� �Է��ϸ� while�� ����
                            if ($KEY.KeyChar -eq 'q' -or $KEY.KeyChar -eq 'Q') {
                                Write-Host "`nQuit this step"
                                break
                            }
                            
                            # c�� �Է��ϸ� clear ����
                            elseif ($KEY.KeyChar -eq 'c' -or $KEY.KeyChar -eq 'C') {
                                Write-Host "`nClear this terminal"
                                Start-Sleep -Milliseconds 500
                                Clear-Host
                                continue
                            }
                        }
                    }

                    # ��� �Ϸ� �� ���ӽ����̽� �������� ���ư��� ���� $ORDER�� 1�� �Ҵ��ϰ� while�� �ٽ� ����
                    $ORDER = 1
                    continue
                }
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return 0
            }

            # �ڷΰ��� ����
            5{
                return 1
            }

        }        
    }
}

# 1-4 ��ü ���ӽ����̽� ���� ����
function Number1_4 {
    foreach ($KUBECONIFG_FILE in $KUBECONFIG_FILES) {
    Write-Host -NoNewline "----------------------------------------------------------------"
    Write-Host -NoNewline "$(${NAMESPACE_LIST}[$COUNT++])".ToUpper() -ForegroundColor Yellow -BackgroundColor Blue
    Write-Host "----------------------------------------------------------------"
    kubectl get pods -o custom-columns=NAME:.metadata.name,POD_STATUS:.status.phase,CONTAINER_READY:.status.containerStatuses[].ready,RESTART_COUNT:.status.containerStatuses[].restartCount,NODE:.spec.nodeName --kubeconfig $KUBECONFIG\$KUBECONIFG_FILE | Out-Host
    }
}

# 1-5 Deployment CPU, Memory ���� Ȯ��
function Number1_5 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # �����̳� ���� & �۾�
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

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return 0
            }

            # �ڷΰ��� ����
            5{
                return 1
            }
        }        
    }
}

# 1-6 Ingress Annotation ���� Ȯ��(Timeout ���� ��)
function Number1_6 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # �α׷��� ����
            2 {
                $ORDER = IngressSelect
                continue
            }

            # �����̳� ���� & �۾�
            3 {
                # Annotation ��ȸ�Ͽ� ����Ʈ�� �Ҵ�
                $ANNOTATIONS = kubectl get ingress $($INGRESSES[$INGRESS_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.metadata.annotations}" | ConvertFrom-Json

                # Annotation�� ����ڿ��� ���
                foreach ($KEY in $ANNOTATIONS.psobject.Properties.Name) {
                    $VALUE = $ANNOTATIONS.$key
                    Write-Host "${KEY}: $VALUE"
                }

                # �α׷��� ������̼� ��ȸ �Ϸ� �� �ĵ� ���� �ܰ���� �����
                $ORDER = 2
                continue
            }
            
            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return 0
            }

            # �ڷΰ��� ����
            5{
                return 1
            }
        }        
    }
}

# 1-7 ���μ��� ����͸� (ps aufxww)
function Number1_7 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # �ĵ� ����
            2 {
                $ORDER = PodSelect
                continue
            }

            # �����̳� ���� & �۾�
            3 {
                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){
                
                # ��ɾ� ������ �Ҵ�
                $COMMAND = @'
watch -n 1 "ps aufxww | grep -v $$ | grep -v 'ps aufxww' | grep -v 'watch'"
'@

                # ��ɾ� ����
                Start-Process -Wait -NoNewWindow -FilePath "kubectl" -ArgumentList "exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c `"$($COMMAND -replace '"', '\"')`""

                # �۾� �Ϸ� �� �ĵ� ���� �ܰ���� �����
                $ORDER = 2
                continue
            }
                else {

                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red

                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                
                    # ��ɾ� ������ �Ҵ�
                    $COMMAND = @'
watch -n 1 "ps aufxww | grep -v $$ | grep -v 'ps aufxww' | grep -v 'watch'"
'@
                    # ��ɾ� ����
                    Start-Process -Wait -NoNewWindow -FilePath "kubectl" -ArgumentList "exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c `"$($COMMAND -replace '"', '\"')`""

                    # �۾� �Ϸ� �� �ĵ� ���� �ܰ���� �����
                    $ORDER = 2
                    continue
                }
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return 0
            }

            # �ڷΰ��� ����
            5{
                return 1
            }
        }        
    }
}

# 2-1 �ĵ� �α� ���(Tail)
function Number2_1 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # �ĵ� ����
            2 {
                $ORDER = PodSelect
                continue
            }

            # �����̳� ���� & �۾�
            3 {
                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){

                    # "�α� ��� �� �Է�" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�α� ��� �� �Է�-------" -BackgroundColor Yellow -ForegroundColor Red

                    # �˸� �޽��� ���
                    Write-Host "If you want to stream logs in real-time, type " -NoNewline
                    Write-Host "'f'" -ForegroundColor Yellow
                    Write-Host "If you want to show full of logs type " -NoNewline
                    Write-Host "'any key'" -ForegroundColor Yellow

                    # Tail �� ����ڿ��� �Է� ����
                    while(1){
                        $TAIL = Read-Host "Tail: "
                        if($TAIL -ne ''){
                            break
                        }
                    }

                    # Tail ���� f�� ��� �ǽð� �α� ���
                    if($TAIL -eq 'f'){
                        Write-Host "Tail real-time logs of " -NoNewline
                        Write-Host "$($PODS[$POD_SELECTION-1])/$($CONTAINERS[$CONTAINER_SELECTION-1])" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                        kubectl logs $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -f | Out-Host
                    }

                    # Tail ���� �������� �ʰų�, �������� ��� -> ��ü �α� ���
                    elseif (![int]::TryParse(${TAIL}, [ref]$null)) {
                        Write-Host "Tail full logs of " -NoNewline
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                        kubectl logs $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} | Out-Host
                    }

                    # Tail ���� �����ϴ� ��� -> �Է��� tail�� ��ŭ �α� ���
		            else {
                        Write-Host "Tail ${TAIL} llines of logs of " -NoNewline
                        Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                        kubectl logs $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} --tail ${TAIL} | Out-Host
                    }

                    # �α� ��� �� �ĵ� ���� �ܰ���� �����
                    $ORDER = 2
                    continue
                }
                else {

                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red

                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # "�α� ��� �� �Է�" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�α� ��� �� �Է�-------" -BackgroundColor Yellow -ForegroundColor Red

                    # �˸� �޽��� ���
                    Write-Host "If you want to stream logs in real-time, type " -NoNewline
                    Write-Host "'f'" -ForegroundColor Yellow
                    Write-Host "If you want to show full of logs type " -NoNewline
                    Write-Host "'any key'" -ForegroundColor Yellow

                    # Tail �� ����ڿ��� �Է� ����
                    while(1){
                        $TAIL = Read-Host "Tail: "
                        if($TAIL -ne ''){
                            break
                        }
                    }

                    # Tail ���� f�� ��� �ǽð� �α� ���
                    if($TAIL -eq 'f'){
                        Write-Host "Tail real-time logs of " -NoNewline
                        Write-Host "$($PODS[$POD_SELECTION-1])/$($CONTAINERS[$CONTAINER_SELECTION-1])" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                        kubectl logs $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -f | Out-Host
                    }

                    # Tail ���� �������� �ʰų�, �������� ��� -> ��ü �α� ���
                    elseif (![int]::TryParse(${TAIL}, [ref]$null)) {
                        Write-Host "Tail full logs of " -NoNewline
                        Write-Host "$($PODS[$POD_SELECTION-1])/$($CONTAINERS[$CONTAINER_SELECTION-1])" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                        kubectl logs $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} | Out-Host
                    }

                    # Tail ���� �����ϴ� ��� -> �Է��� tail�� ��ŭ �α� ���
		            else {
                        Write-Host "Tail ${TAIL} llines of logs of " -NoNewline
                        Write-Host "$($PODS[$POD_SELECTION-1])/$($CONTAINERS[$CONTAINER_SELECTION-1])" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                        kubectl logs $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1])  --kubeconfig ${KUBECONFIG_PATH} --tail ${TAIL} | Out-Host
                    }

                    # �α� ��� �� �ĵ� ���� �ܰ���� �����
                    $ORDER = 2
                    continue
                }
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return 0
            }

            # �ڷΰ��� ����
            5{
                return 2
            }
        }        
    }
}

# 2-2 �ĵ� �α� ���� �ٿ�ε�
function Number2_2 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){

        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # �ĵ� ����
            2 {
                $ORDER = PodSelect
                continue
            }

            # �����̳� ���� & �۾�
            3 {

                # �αװ� ����� ��θ� ������ ����
                
                $LOG_PATH = "$HOME\Desktop\Pod_logs\${NAMESPACE}"

		        # �α׸� ������ ��ΰ� ���� ��� ����
                if (-not (Test-Path $LOG_PATH)) {
                    New-Item -ItemType Directory -Path $LOG_PATH
                }

                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){

                    # �α� ���� ����
                    $DATE = Get-Date -Format "yyyy/MM/dd/HH/mm"
                    Write-Host "Saved to " -NoNewline
                    Write-Host "$LOG_PATH\$($PODS[$POD_SELECTION-1])_${DATE}.txt" -ForegroundColor Yellow
		            kubectl logs $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} > $LOG_PATH\$($PODS[$POD_SELECTION-1])_${DATE}.txt

                    # ����� �α������� �������� ����
                    Write-Host "type '" -NoNewline; Write-Host "y" -NoNewline -ForegroundColor Yellow; Write-Host "' to open a log file";
                    Write-Host "type '" -NoNewline; Write-Host "any key" -NoNewline -ForegroundColor Yellow; Write-Host "' to skip";
                    $OPEN_LOG_FILE = Read-Host " "

                    # y�� �Է��� ��� ����� �α������� notepad�� ����
                    if($OPEN_LOG_FILE -eq "y" -or $OPEN_LOG_FILE -eq "Y") {
                        Write-Host "Now opening " -NoNewline
                        Write-Host "$LOG_PATH\$($PODS[$POD_SELECTION-1])_${DATE}.txt" -ForegroundColor Yellow
                        notepad $LOG_PATH\$($PODS[$POD_SELECTION-1])_${DATE}.txt
                    }

                    # �α� ���� ���� �Ϸ� �� �ĵ� ���� �ܰ���� �����
                    $ORDER = 2
                    continue
                }

                # �ĵ峻 �����̳ʰ� 2�� �̻��� ���
                else {
                    
                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red

                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # �α� ���� ����
                    $DATE = Get-Date -Format "yyyy/MM/dd/HH/mm"
                    Write-Host "Saved to " -NoNewline
                    Write-Host "$LOG_PATH\$($PODS[$POD_SELECTION-1])_$($CONTAINERS[$CONTAINER_SELECTION-1])_${DATE}.txt" -ForegroundColor Yellow
		            kubectl logs $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} > $LOG_PATH\$($PODS[$POD_SELECTION-1])_$($CONTAINERS[$CONTAINER_SELECTION-1])_${DATE}.txt

                    # ����� �α������� �������� ����
                    Write-Host "type '" -NoNewline; Write-Host "y" -NoNewline -ForegroundColor Yellow; Write-Host "' to open a log file";
                    Write-Host "type '" -NoNewline; Write-Host "any key" -NoNewline -ForegroundColor Yellow; Write-Host "' to skip";
                    $OPEN_LOG_FILE = Read-Host " "
                    
                    # y�� �Է��� ��� ����� �α������� notepad�� ����
                    if($OPEN_LOG_FILE -eq "y" -or $OPEN_LOG_FILE -eq "Y") {
                        Write-Host "Now opening " -NoNewline
                        Write-Host "$LOG_PATH\$($PODS[$POD_SELECTION-1])_$($CONTAINERS[$CONTAINER_SELECTION-1])_${DATE}.txt" -ForegroundColor Yellow
                        notepad $LOG_PATH\$($PODS[$POD_SELECTION-1])_$($CONTAINERS[$CONTAINER_SELECTION-1])_${DATE}.txt
                    }

                    # �α� ���� ���� �Ϸ� �� �ĵ� ���� �ܰ���� �����
                    $ORDER = 2
                    continue
                }
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return 0
            }

            # �ڷΰ��� ����
            5{
                return 2
            }
        }        
    }
}

# 2-3 Nginx Ingress Controller �α� �ǽð� Ȯ��(access.log, error.log)
function Number2_3 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # Nginx Ingress Controller ����
            2 {

                # Nginx Ingress Controller Pod �� �Ľ��Ͽ� ������ �Ҵ�
                $NGINX_PODS = (kubectl get pods --selector app=ingress-controller -o=name --kubeconfig ${KUBECONFIG_PATH}).replace("pod/","")
                
                # Nginx Ingress Controller �� 1���� ���
                if( $(${NGINX_PODS}.Count) -eq 1 ){
                    $NGINX_POD = $NGINX_PODS
                    Write-Host "Selected Nginx Ingress Controller: " -NoNewline
                    Write-Host "$NGINX_POD" -ForegroundColor Blue
                    # �α� Ȯ�� �Ϸ� �� ���ӽ����̽� ���� �ܰ�� ���ư��� ���� ORDER������ 1�� �Ҵ��ϰ� continue ����
                    $ORDER = 3
                    continue
                }

                # Nginx Ingress Controller �� 2�� �̻��� ���
                else {
                    
                    # "�α׷��� ��Ʈ�ѷ� �ĵ� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�α׷��� ��Ʈ�ѷ� �ĵ� ����-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0
                    
                    # ����ڿ��� �α׷��� ��Ʈ�ѷ� �������� ���
                    Write-Host "Select Nginx Ingress Controller" -ForegroundColor Yellow
                    foreach (${NGINX_POD} in $NGINX_PODS) {
                        $COUNT++
                        Write-Host "${COUNT}: $NGINX_POD"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message

                    # ������� Nginx Ingress Controller ������ �Է� �޾� ���� �Ҵ�
                    while(1) {
                        $NGINX_SELECTION = Read-Host " "
                        if($NGINX_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${NGINX_SELECTION} -eq "q" -or ${NGINX_SELECTION} -eq "f" -or ${NGINX_SELECTION} -eq "b" -or ${NGINX_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b1_r2 -Selection ${NGINX_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${NGINX_SELECTION}, [ref]$null) -or [int]${NGINX_SELECTION} -lt 1 -or [int]${NGINX_SELECTION} -gt $($NGINX_PODS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($NGINX_PODS.Count)" -ForegroundColor Red
                        continue
                    }

                    # ����ڰ� �������� ���� �Է����� ���
                    else {
                        $NGINX_POD = $($NGINX_PODS[$NGINX_SELECTION-1])
                        Write-Host "Selected Nginx Ingress Controller: " -NoNewline
                        Write-Host "$NGINX_POD" -ForegroundColor Blue
                    }
                    
                    # �α� Ȯ�� �ܰ�� �Ѿ�� ���� ORDER������ 3�� �Ҵ��ϰ� continue ����
                    $ORDER = 3
                    continue
                }
            }

            # access.log �Ǵ� error.log ����
            3 {

                # "�α� ���� ����" �ܰ� �˸� �޽�ġ ���
                Write-Host "-------�α� ���� ����-------" -BackgroundColor Yellow -ForegroundColor Red
                # 1 �� �Է��ϸ� access.log �� Ȯ���Ѵٴ� �޽��� ���
                Write-Host "1: " -NoNewline
                Write-Host "access.log"
                
                # 2 �� �Է��ϸ� error.log �� Ȯ���Ѵٴ� �޽��� ���
                Write-Host "2: " -NoNewline
                Write-Host "error.log"

                # ��ũ��Ʈ �ܰ� �̵� ���� ���
                Message_NoRefresh

                # ������� Nginx Ingress Controller ������ �Է� �޾� ���� �Ҵ�
                while(1) {
                    $LOG_SELECTION = Read-Host ' '
                    if($LOG_SELECTION -ne ''){
                        break
                    }
                }
                
                # ����� ���� ���� Ȯ�� (Nginx Ingress Controller�� 1���� ���)
                if ($($NGINX_PODS.Count) -eq 1 -and (${LOG_SELECTION} -eq "q" -or ${LOG_SELECTION} -eq "f" -or ${LOG_SELECTION} -eq "b")){
                    $ORDER = Check_Selection_b1_r2 -Selection ${LOG_SELECTION}
                    continue
                }

                # ����� ���� ���� Ȯ�� (Nginx Ingress Controller�� 2�� �̻��� ���)
                elseif ($($NGINX_PODS.Count) -ge 2 -and (${LOG_SELECTION} -eq "q" -or ${LOG_SELECTION} -eq "f" -or ${LOG_SELECTION} -eq "b")){
                    $ORDER = Check_Selection_b2_r3 -Selection ${LOG_SELECTION}
                    continue
                }

                # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                elseif (![int]::TryParse(${LOG_SELECTION}, [ref]$null) -or [int]${LOG_SELECTION} -lt 1 -or [int]${LOG_SELECTION} -gt 2 ) {
                    Write-Host "Invalid selection. Please enter a number between 1 and 2" -ForegroundColor Red
                    continue
                }
                
                # ����ڰ� 1�� ������ ��� access.log ���
                elseif (${LOG_SELECTION} -eq 1) {

                    # �α� Ȯ�� ��� ���
                    Write-Host "Checking real-time log of access.log of " -NoNewline; Write-Host "${NGINX_POD}" -ForegroundColor Green

                    # access.log Ȯ��
                    kubectl exec -it ${NGINX_POD} -c ingress-controller --kubeconfig ${KUBECONFIG_PATH} -- tail -f /var/log/nginx/access.log | Out-Host
                    
                }

                # ����ڰ� 2�� ������ ��� error.log ���
                elseif (${LOG_SELECTION} -eq 2) {

                    # �α� Ȯ�� ��� ���
                    Write-Host "Checking real-time log of error.log of " -NoNewline; Write-Host "${NGINX_POD}" -ForegroundColor Green

                    # error.log Ȯ��
                    kubectl exec -it ${NGINX_POD} -c ingress-controller --kubeconfig ${KUBECONFIG_PATH} -- tail -f /var/log/nginx/error.log | Out-Host


                }

                # Nginx Ingrss Controller�� 1���� ��� �α� tail �� �����ϰ� �ٽ� ���ӽ����̽� �������� ���ư��� ���� ORDER ������ 1�� �Ҵ��ϰ� continue
                if ($($NGINX_PODS.Count) -eq 1) {
                    $ORDER = 1
                    continue
                }
                # Nginx Ingrss Controller�� 2�� �̻��� ��� �α� tail �� �����ϰ� �ٽ� Nginx Ingress Controller �������� ���ư��� ���� ORDER ������ 2�� �Ҵ��ϰ� continue
                elseif ($($NGINX_PODS.Count) -ge 2) {
                    $ORDER = 2
                    continue
                }
            }
            
            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return 0
            }

            # �ڷΰ��� ����
            5{
                return 2
            }
        }    
    }
}

# 3-1 JSTAT Ȯ��
function Number3_1 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){

        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # �ĵ� ����
            2 {
                $ORDER = PodSelect
                continue
            }

            # �����̳� ���� & �۾�
            3 {

                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){
                    
                    # ����ڿ��� "JSTAT �����" �޽��� ���
                    Write-Host -NoNewline "Watching JSTAT to "
                    Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green
                    
                    # ���õ� �ĵ忡�� JSTAT Ȯ��
                    try{

                        # ���μ��� ID ���� �Ҵ�
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server" 2> $null

                        # ���콺 �ĵ尡 �ƴ� ��� ���� ó��
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # ���콺 �ĵ尡 ���� ��� ���������� ��ɾ� ����
                        else{
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- jstat -gcutil -h20 -t $PROCESS_ID 2000 | Out-Host
                        }
                    }
                    catch{

                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �ĵ�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # JSTAT ��� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ����
                    $ORDER = 2
                    continue
                }

                # �ĵ峻 �����̳ʰ� 2�� �̻��� ���
                else {
                    
                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # ����ڿ��� "JSTAT �����" �޽��� ���
                    Write-Host -NoNewline "Watching JSTAT from "
                    Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green

                    # ���õ� �ĵ忡�� JSTAT Ȯ��
                    try{

                        # ���μ��� ID ���� �Ҵ�
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # ���콺 �����̳ʰ� �ƴ� ��� ���� ó��
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # ���콺 �����̳ʰ� ���� ��� ���������� ��ɾ� ����
                        else{
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- jstat -gcutil -h20 -t $PROCESS_ID 2000 | Out-Host
                        }
                    }
                    catch{
                        
                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �����̳�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # JSTAT ��� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ����
                    $ORDER = 2
                    continue
                    
                }
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return 0
            }

            # �ڷΰ��� ����
            5{
                return 3
            }
        }        
    }
}

# 3-2 JVM Heap ���� ���� ���� �ٿ�ε�
function Number3_2 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # �ĵ� ����
            2 {
                $ORDER = PodSelect
                continue
            }

            # �����̳� ���� & �۾�
            3 {

                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # ���� ������ ���� DATE ���� �Ҵ�
                $DATE = Get-Date -Format "yyMMdd_HHmm"

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){

                    # �� ���� ���� �޽��� ���
                    Write-Host -NoNewline "Creating heap dump file to "
                    Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                    # ���õ� �ĵ忡�� �� ���� ����
                    try{

                        # ���μ��� ID ���� �Ҵ�
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # ���콺 �����̳ʰ� �ƴ� ��� ���� ó��
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # ���콺 �����̳ʰ� ���� ��� ���������� ��ɾ� ����
                        else{

                            # jmap ��ɾ� ���� �Ҵ�
                            $COMMAND = "jmap -dump:format=b,file=$($PODS[$POD_SELECTION-1])_${DATE}.hprof ${PROCESS_ID}"
                            
                            # �����̳� ���� �ӽ÷� ������ �� ���� ��� ����
                            $CONTAINER_PATH = "$($PODS[$POD_SELECTION-1]):$($PODS[$POD_SELECTION-1])_${DATE}.hprof"

                            # ���� ���� ��� ����
                            $LOCAL_PATH = $HOME.replace("C:","").replace("\","/") + "/Desktop/$($PODS[$POD_SELECTION-1])_${DATE}.hprof"
                            
                            # ���õ� �ĵ忡�� �� ���� ����
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c ${COMMAND} | Out-Host

                            #  �� ���� ���� �ٿ�ε�
                            Write-Host "Downloading heap dump file to $LOCAL_PATH ..."
                            kubectl cp $CONTAINER_PATH $LOCAL_PATH --kubeconfig ${KUBECONFIG_PATH} --warnings-as-errors=false | Out-Host

                            # �����̳� ���� �����ߴ� �ӽ� �� ���� ���� ����
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- rm ./$($PODS[$POD_SELECTION-1])_${DATE}.hprof | Out-Host
                        }
                    }
                    catch{
                        
                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �ĵ�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }



                    # �� ���� �ٿ�ε� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 2
                    continue
                }
                else {
                    
                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # �� ���� ���� �޽��� ���
                    Write-Host -NoNewline "Creating heap dump file to "
                    Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green

                    # ���õ� �ĵ忡�� �� ���� ����
                    try{

                        # ���μ��� ID ���� �Ҵ�
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # ���콺 �����̳ʰ� �ƴ� ��� ���� ó��
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # ���콺 �����̳ʰ� ���� ��� ���������� ��ɾ� ����
                        else{
                            # jmap ��ɾ� ���� �Ҵ�
                            $COMMAND = "jmap -dump:format=b,file=$($PODS[$POD_SELECTION-1])_${DATE}.hprof ${PROCESS_ID}"
                            
                            # �����̳� ���� �ӽ÷� ������ �� ���� ��� ����
                            $CONTAINER_PATH = "$($PODS[$POD_SELECTION-1]):$($PODS[$POD_SELECTION-1])_${DATE}.hprof"
                            
                            # ���� ���� ��� ����
                            $LOCAL_PATH = $HOME.replace("C:","").replace("\","/") + "/Desktop/$($PODS[$POD_SELECTION-1])_${DATE}.hprof"

                            # ���õ� �ĵ忡�� �� ���� ����
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c ${COMMAND} | Out-Host
                            Write-Host "Downloading heap dump file to $LOCAL_PATH ..."

                            #  �� ���� ���� �ٿ�ε�
                            kubectl cp -c $($CONTAINERS[$CONTAINER_SELECTION-1]) $CONTAINER_PATH $LOCAL_PATH --kubeconfig ${KUBECONFIG_PATH} --warnings-as-errors=false | Out-Host

                            # �����̳� ���� �����ߴ� �ӽ� �� ���� ���� ����
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- rm ./$($PODS[$POD_SELECTION-1])_${DATE}.hprof | Out-Host
                        }
                    }
                    catch{
                        
                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �����̳�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # �� ���� �ٿ�ε� �Ϸ� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 2
                    continue
                    
                }
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return 0
            }

            # �ڷΰ��� ����
            5{
                return 3
            }
        }        
    }
}

# 3-3 jinfo Ȯ��
function Number3_3 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # �ĵ� ����
            2 {
                $ORDER = PodSelect
                continue
            }

            # �����̳� ���� & �۾�
            3 {

                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){
                    
                    # �ȳ� �޽��� ���
                    Write-Host -NoNewline "Checking jinfo of "
                    Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                    # ���õ� �ĵ忡�� jinfo Ȯ��
                    try{

                        # ���μ��� ID ���� �Ҵ�
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # ���콺 �����̳ʰ� �ƴ� ��� ���� ó��
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # ���콺 �����̳ʰ� ���� ��� ���������� ��ɾ� ����
                        else{
                            
                            # jinfo ��ɾ� ���� �Ҵ�
                            $COMMAND = "jinfo ${PROCESS_ID}"

                            # ���õ� �ĵ忡�� jinfo Ȯ��
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c ${COMMAND} | Out-Host
                        }
                    }
                    catch{
                        
                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �ĵ�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }


                    
                    # jinfo Ȯ�� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 2
                    continue
                }

                # �ĵ峻 �����̳ʰ� 2�� �̻��� ���
                else {
                                        
                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }
                    
                    # �ȳ� �޽��� ���
                    Write-Host -NoNewline "Checking jinfo of "
                    Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green

                    # ���õ� �ĵ忡�� jinfo Ȯ��
                    try{

                        # ���μ��� ID ���� �Ҵ�
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # ���콺 �����̳ʰ� �ƴ� ��� ���� ó��
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # ���콺 �����̳ʰ� ���� ��� ���������� ��ɾ� ����
                        else{
                            
                            # jinfo ��ɾ� ���� �Ҵ�
                            $COMMAND = "jinfo ${PROCESS_ID}"

                            # ���õ� �ĵ� �����̳ʿ��� jinfo Ȯ��
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c ${COMMAND} | Out-Host
                        }
                    }
                    catch{
                        
                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �����̳�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # jinfo Ȯ�� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 2
                    continue
                    
                }
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return 0
            }

            # �ڷΰ��� ����
            5{
                return 3
            }
        }        
    }
}

# 3-4 jstack ��ȸ
function Number3_4 {

    # �Լ��� ORDER ������ ���� �ڷΰ���, �� ó���ܰ�� �̵�, ���ΰ�ħ ���� ����
    param (
        $ORDER
    )

    # �ܰ� �̵��� ���� While���� Switch�� ���
    while(1){
        Switch ($ORDER) {

            # ���ӽ����̽� ����
            1 {
                $ORDER = NamespaceSelect_Inner
                continue
            }

            # �ĵ� ����
            2 {
                $ORDER = PodSelect
                continue
            }

            # �����̳� ���� & �۾�
            3 {

                # �����̳� ��� ����Ʈ�� �Ҵ�
                $CONTAINERS = (kubectl get pods $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -o jsonpath="{.spec.containers[*].name}").split(" ")

                # �ĵ峻 �����̳ʰ� 1���� ���
                if( $($CONTAINERS.Count) -eq 1 ){
                    
                    # �ȳ��޽��� ���
                    Write-Host -NoNewline "Checking jstack of "
                    Write-Host "$($PODS[$POD_SELECTION-1])" -ForegroundColor green

                    # ���õ� �ĵ忡�� jstack Ȯ��
                    try{

                        # ���μ��� ID ���� �Ҵ�
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # ���콺 �����̳ʰ� �ƴ� ��� ���� ó��
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # ���콺 �����̳ʰ� ���� ��� ���������� ��ɾ� ����
                        else{
                            
                            # jstack ��ɾ� ���� �Ҵ�
                            $COMMAND = "jstack -F ${PROCESS_ID}"

                            # ���õ� �ĵ忡�� jstack Ȯ��
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c ${COMMAND} | Out-Host
                        }
                    }
                    catch{
                        
                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �ĵ�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # jstack Ȯ�� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 2
                    continue
                }

                # �ĵ峻 �����̳ʰ� 2�� �̻��� ���
                else {
                    
                    # "�����̳� ����" �ܰ� �˸� �޽�ġ ���
                    Write-Host "-------�����̳� ����-------" -BackgroundColor Yellow -ForegroundColor Red
                    
                    # ����ڰ� ��ȿ���� ���� ���� �Է��Ͽ� �ٽ� ������ ��츦 ���� �������� 0���� �ʱ�ȭ
                    [int]$COUNT = 0

                    # ����ڿ��� �����̳� �������� ���
                    Write-Host "Select a container." -ForegroundColor Yellow
                    foreach (${CONTAINER} in $CONTAINERS) {
                        $COUNT++
                        Write-Host "${COUNT}: $CONTAINER"
                    }

                    # ��ũ��Ʈ �ܰ� �̵� ���� ���
                    Message

                    # ������� �����̳� ������ �Է� �޾� ���� �Ҵ�
                    while(1){
                        $CONTAINER_SELECTION = Read-Host "Choose a container"
                        if($CONTAINER_SELECTION -ne '') {
                            break
                        }
                    }

                    # ����� ���� ���� Ȯ��
                    if (${CONTAINER_SELECTION} -eq "q" -or ${CONTAINER_SELECTION} -eq "f" -or ${CONTAINER_SELECTION} -eq "b" -or ${CONTAINER_SELECTION} -eq "r"){
                        $ORDER = Check_Selection_b2_r3 -Selection ${CONTAINER_SELECTION}
                        continue
                    }

                    # ����ڰ� ��ȿ���� ���� ���� �Է��� ��� while ���� ó������ ����
                    elseif (![int]::TryParse(${CONTAINER_SELECTION}, [ref]$null) -or [int]${CONTAINER_SELECTION} -lt 1 -or [int]${CONTAINER_SELECTION} -gt $($CONTAINERS.Count) ) {
                        Write-Host "Invalid selection. Please enter a number between 1 and $($CONTAINERS.Count)" -ForegroundColor Red
                        continue
                    }

                    # ���õ� �ĵ忡�� jstack Ȯ��
                    Write-Host -NoNewline "Checking jstack of "
                    Write-Host "$($CONTAINERS[$CONTAINER_SELECTION-1]) of $($PODS[$POD_SELECTION-1])" -ForegroundColor green
		            
                    # ���õ� �ĵ忡�� jstack Ȯ��
                    try{

                        # ���μ��� ID ���� �Ҵ�
                        $PROCESS_ID = kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- pgrep -f "/opt/java/bin/java -server"  2> $null

                        # ���콺 �����̳ʰ� �ƴ� ��� ���� ó��
                        if ($LASTEXITCODE -eq 1) {
                            throw "$LASTEXITCODE"
                        }

                        # ���콺 �����̳ʰ� ���� ��� ���������� ��ɾ� ����
                        else{
                            
                            # jstack ��ɾ� ���� �Ҵ�
                            $COMMAND = "jstack -F ${PROCESS_ID}"

                            # ���õ� �ĵ� �����̳ʿ��� jstack Ȯ��
                            kubectl exec -it $($PODS[$POD_SELECTION-1]) -c $($CONTAINERS[$CONTAINER_SELECTION-1]) --kubeconfig ${KUBECONFIG_PATH} -- sh -c ${COMMAND} | Out-Host
                        }
                    }
                    catch{
                        
                        # �����޽��� ���
                        Write-Host "�ݵ�� " -NoNewline; Write-Host "Jeus �����̳�" -NoNewline -ForegroundColor Red; Write-Host "�� �����ϼ���.";
                    }

                    # jstack Ȯ�� �� �ĵ� ���� �ܰ�� ���ư��� ���� ����
                    $ORDER = 2
                    continue
                }
            }

            # �ĵ�, ���ӽ����̽�, �α׷��� ���õ�� f �Է��� ���� ��� �� ó�� �ܰ�� ���ư��� ���� ORDER������ 4�� �Ҵ��Ͽ� return ����
            4{
                return 0
            }

            # �ڷΰ��� ����
            5{
                return 3
            }
        }        
    }
}

# �۾� ���� ����
SelectJob -STEP 0


'''
2.0.4 Patch Note
230731
- "4. Jeus Admin ��ɾ� ���� -> ���ӽ����̽� ���� -> �ĵ� ����" ���� f�� �Է��Ͽ� �� ó�� �ܰ�� �̵��� ��� ���ʿ��� 0 �� ��� �Ǵ� ���� ����

2.0.5 Patch Note
231010
- �ĵ彩 ���� ��ɾ� ���� sh -c "clear; (bash || ash || sh)" �� /bin/bash �� ����

'''