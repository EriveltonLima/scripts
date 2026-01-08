#!/bin/bash

# Script Interativo para Comandos CLI do Proxmox VE
# Autor: Script para gerenciamento do Proxmox via terminal

clear
echo "=================================================="
echo "    PROXMOX VE - SCRIPT INTERATIVO CLI"
echo "=================================================="
echo ""

# Função para pausar e aguardar input do usuário
pause() {
    echo ""
    read -p "Pressione ENTER para continuar..."
    clear
}

# Função para validar se o ID é numérico
validate_id() {
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Erro: ID deve ser numérico!"
        return 1
    fi
    return 0
}

# Função para confirmação de ações destrutivas
confirm_action() {
    local action="$1"
    local id="$2"
    echo ""
    echo "⚠️  ATENÇÃO: Esta ação é IRREVERSÍVEL!"
    echo "Você está prestes a $action o ID: $id"
    echo ""
    read -p "Digite 'CONFIRMO' para prosseguir ou qualquer outra coisa para cancelar: " confirmation
    
    if [ "$confirmation" != "CONFIRMO" ]; then
        echo "Operação cancelada pelo usuário."
        return 1
    fi
    return 0
}

# Menu principal
show_main_menu() {
    echo "Escolha uma opção:"
    echo ""
    echo "=== VIRTUAL MACHINES (QEMU/KVM) ==="
    echo "1)  Listar VMs"
    echo "2)  Criar VM"
    echo "3)  Iniciar VM"
    echo "4)  Parar VM"
    echo "5)  Reiniciar VM"
    echo "6)  Status da VM"
    echo "7)  Configuração da VM"
    echo "8)  Snapshot da VM"
    echo "9)  Clonar VM"
    echo "10) Migrar VM"
    echo "11) Desbloquear VM (unlock)"
    echo "12) ❌ Remover VM"
    echo ""
    echo "=== CONTAINERS (LXC) ==="
    echo "13) Listar Containers"
    echo "14) Criar Container"
    echo "15) Iniciar Container"
    echo "16) Parar Container"
    echo "17) Status do Container"
    echo "18) Entrar no Container"
    echo "19) Snapshot do Container"
    echo "20) Desbloquear Container (unlock)"
    echo "21) ❌ Remover Container"
    echo ""
    echo "=== SISTEMA E CLUSTER ==="
    echo "22) Status do Cluster"
    echo "23) Listar Storages"
    echo "24) Backup (vzdump)"
    echo "25) Listar Templates"
    echo ""
    echo "0) Sair"
    echo ""
    read -p "Digite sua opção: " opcao
}

# Funções para VMs
vm_list() {
    echo "=== LISTANDO VIRTUAL MACHINES ==="
    qm list
}

vm_create() {
    echo "=== CRIAR NOVA VM ==="
    read -p "Digite o ID da VM: " vmid
    validate_id "$vmid" || return
    read -p "Nome da VM: " vmname
    read -p "Memória (MB) [2048]: " memory
    memory=${memory:-2048}
    read -p "Cores [2]: " cores
    cores=${cores:-2}
    read -p "Sockets [1]: " sockets
    sockets=${sockets:-1}
    
    echo "Criando VM $vmid com nome '$vmname'..."
    qm create $vmid --name "$vmname" --memory $memory --cores $cores --sockets $sockets --net0 virtio,bridge=vmbr0 --ostype l26
    echo "VM criada com sucesso!"
}

vm_start() {
    echo "=== INICIAR VM ==="
    read -p "Digite o ID da VM: " vmid
    validate_id "$vmid" || return
    echo "Iniciando VM $vmid..."
    qm start $vmid
    echo "VM iniciada!"
}

vm_stop() {
    echo "=== PARAR VM ==="
    read -p "Digite o ID da VM: " vmid
    validate_id "$vmid" || return
    echo "Parando VM $vmid..."
    qm stop $vmid
    echo "VM parada!"
}

vm_reboot() {
    echo "=== REINICIAR VM ==="
    read -p "Digite o ID da VM: " vmid
    validate_id "$vmid" || return
    echo "Reiniciando VM $vmid..."
    qm reboot $vmid
    echo "VM reiniciada!"
}

vm_status() {
    echo "=== STATUS DA VM ==="
    read -p "Digite o ID da VM: " vmid
    validate_id "$vmid" || return
    qm status $vmid
}

vm_config() {
    echo "=== CONFIGURAÇÃO DA VM ==="
    read -p "Digite o ID da VM: " vmid
    validate_id "$vmid" || return
    qm config $vmid
}

vm_snapshot() {
    echo "=== SNAPSHOT DA VM ==="
    read -p "Digite o ID da VM: " vmid
    validate_id "$vmid" || return
    read -p "Nome do snapshot: " snapname
    echo "Criando snapshot '$snapname' da VM $vmid..."
    qm snapshot $vmid $snapname
    echo "Snapshot criado!"
}

vm_clone() {
    echo "=== CLONAR VM ==="
    read -p "ID da VM origem: " source_vmid
    validate_id "$source_vmid" || return
    read -p "ID da nova VM: " new_vmid
    validate_id "$new_vmid" || return
    read -p "Nome da nova VM: " new_name
    echo "Clonando VM $source_vmid para $new_vmid..."
    qm clone $source_vmid $new_vmid --name "$new_name" --full
    echo "Clone criado!"
}

vm_migrate() {
    echo "=== MIGRAR VM ==="
    read -p "Digite o ID da VM: " vmid
    validate_id "$vmid" || return
    read -p "Nó de destino: " target_node
    echo "Migrando VM $vmid para $target_node..."
    qm migrate $vmid $target_node
    echo "Migração concluída!"
}

vm_unlock() {
    echo "=== DESBLOQUEAR VM ==="
    read -p "Digite o ID da VM: " vmid
    validate_id "$vmid" || return
    echo "Desbloqueando VM $vmid..."
    qm unlock $vmid
    echo "VM desbloqueada!"
}

vm_destroy() {
    echo "=== REMOVER VM ==="
    echo "Listando VMs disponíveis:"
    qm list
    echo ""
    read -p "Digite o ID da VM a ser REMOVIDA: " vmid
    validate_id "$vmid" || return
    
    # Verificar se a VM existe
    if ! qm status $vmid &>/dev/null; then
        echo "Erro: VM $vmid não encontrada!"
        return
    fi
    
    # Mostrar informações da VM
    echo ""
    echo "Informações da VM a ser removida:"
    qm config $vmid | head -10
    echo ""
    
    # Confirmar ação
    confirm_action "REMOVER COMPLETAMENTE a VM" "$vmid" || return
    
    # Verificar se está rodando e parar se necessário
    vm_status=$(qm status $vmid | grep -o "status: [a-z]*" | cut -d' ' -f2)
    if [ "$vm_status" = "running" ]; then
        echo "VM está rodando. Parando VM primeiro..."
        qm stop $vmid
        sleep 3
    fi
    
    # Remover VM
    echo "Removendo VM $vmid..."
    read -p "Remover também os discos? (s/N): " remove_disks
    if [[ "$remove_disks" =~ ^[Ss]$ ]]; then
        qm destroy $vmid --purge
        echo "VM $vmid removida com todos os discos!"
    else
        qm destroy $vmid
        echo "VM $vmid removida (discos preservados)!"
    fi
}

# Funções para Containers
ct_list() {
    echo "=== LISTANDO CONTAINERS ==="
    pct list
}

ct_create() {
    echo "=== CRIAR NOVO CONTAINER ==="
    read -p "Digite o ID do Container: " ctid
    validate_id "$ctid" || return
    read -p "Nome do Container: " ctname
    read -p "Template (ex: debian-11-standard_11.7-1_amd64.tar.zst): " template
    read -p "Memória (MB) [512]: " memory
    memory=${memory:-512}
    read -p "Swap (MB) [512]: " swap
    swap=${swap:-512}
    read -p "Storage [local-lvm]: " storage
    storage=${storage:-local-lvm}
    
    echo "Criando container $ctid..."
    pct create $ctid /var/lib/vz/template/cache/$template --hostname $ctname --memory $memory --swap $swap --storage $storage --net0 name=eth0,bridge=vmbr0,ip=dhcp
    echo "Container criado!"
}

ct_start() {
    echo "=== INICIAR CONTAINER ==="
    read -p "Digite o ID do Container: " ctid
    validate_id "$ctid" || return
    echo "Iniciando container $ctid..."
    pct start $ctid
    echo "Container iniciado!"
}

ct_stop() {
    echo "=== PARAR CONTAINER ==="
    read -p "Digite o ID do Container: " ctid
    validate_id "$ctid" || return
    echo "Parando container $ctid..."
    pct stop $ctid
    echo "Container parado!"
}

ct_status() {
    echo "=== STATUS DO CONTAINER ==="
    read -p "Digite o ID do Container: " ctid
    validate_id "$ctid" || return
    pct status $ctid
}

ct_enter() {
    echo "=== ENTRAR NO CONTAINER ==="
    read -p "Digite o ID do Container: " ctid
    validate_id "$ctid" || return
    echo "Entrando no container $ctid (digite 'exit' para sair)..."
    pct enter $ctid
}

ct_snapshot() {
    echo "=== SNAPSHOT DO CONTAINER ==="
    read -p "Digite o ID do Container: " ctid
    validate_id "$ctid" || return
    read -p "Nome do snapshot: " snapname
    echo "Criando snapshot '$snapname' do container $ctid..."
    pct snapshot $ctid $snapname
    echo "Snapshot criado!"
}

ct_unlock() {
    echo "=== DESBLOQUEAR CONTAINER ==="
    read -p "Digite o ID do Container: " ctid
    validate_id "$ctid" || return
    echo "Desbloqueando container $ctid..."
    pct unlock $ctid
    echo "Container desbloqueado!"
}

ct_destroy() {
    echo "=== REMOVER CONTAINER ==="
    echo "Listando containers disponíveis:"
    pct list
    echo ""
    read -p "Digite o ID do Container a ser REMOVIDO: " ctid
    validate_id "$ctid" || return
    
    # Verificar se o container existe
    if ! pct status $ctid &>/dev/null; then
        echo "Erro: Container $ctid não encontrado!"
        return
    fi
    
    # Mostrar informações do container
    echo ""
    echo "Informações do container a ser removido:"
    pct config $ctid | head -10
    echo ""
    
    # Confirmar ação
    confirm_action "REMOVER COMPLETAMENTE o Container" "$ctid" || return
    
    # Verificar se está rodando e parar se necessário
    ct_status=$(pct status $ctid | grep -o "status: [a-z]*" | cut -d' ' -f2)
    if [ "$ct_status" = "running" ]; then
        echo "Container está rodando. Parando container primeiro..."
        pct stop $ctid
        sleep 3
    fi
    
    # Remover container
    echo "Removendo container $ctid..."
    read -p "Remover também os discos/volumes? (s/N): " remove_disks
    if [[ "$remove_disks" =~ ^[Ss]$ ]]; then
        pct destroy $ctid --purge
        echo "Container $ctid removido com todos os volumes!"
    else
        pct destroy $ctid
        echo "Container $ctid removido (volumes preservados)!"
    fi
}

# Funções do sistema
cluster_status() {
    echo "=== STATUS DO CLUSTER ==="
    pvecm status
}

storage_list() {
    echo "=== LISTANDO STORAGES ==="
    pvesm status
}

backup_create() {
    echo "=== CRIAR BACKUP ==="
    read -p "ID da VM/Container: " vmid
    validate_id "$vmid" || return
    read -p "Storage de destino [local]: " storage
    storage=${storage:-local}
    echo "Criando backup de $vmid..."
    vzdump $vmid --storage $storage --compress gzip
    echo "Backup criado!"
}

template_list() {
    echo "=== LISTANDO TEMPLATES ==="
    pveam list local
}

# Loop principal
while true; do
    show_main_menu
    
    case $opcao in
        1) vm_list; pause ;;
        2) vm_create; pause ;;
        3) vm_start; pause ;;
        4) vm_stop; pause ;;
        5) vm_reboot; pause ;;
        6) vm_status; pause ;;
        7) vm_config; pause ;;
        8) vm_snapshot; pause ;;
        9) vm_clone; pause ;;
        10) vm_migrate; pause ;;
        11) vm_unlock; pause ;;
        12) vm_destroy; pause ;;
        13) ct_list; pause ;;
        14) ct_create; pause ;;
        15) ct_start; pause ;;
        16) ct_stop; pause ;;
        17) ct_status; pause ;;
        18) ct_enter; pause ;;
        19) ct_snapshot; pause ;;
        20) ct_unlock; pause ;;
        21) ct_destroy; pause ;;
        22) cluster_status; pause ;;
        23) storage_list; pause ;;
        24) backup_create; pause ;;
        25) template_list; pause ;;
        0) 
            echo "Saindo do script..."
            exit 0
            ;;
        *)
            echo "Opção inválida! Tente novamente."
            pause
            ;;
    esac
done
