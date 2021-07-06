#get credentials for gold images and set vars
$credentials = Get-Credential
$location = "West US 2"
$rg = "tmp_elk_images"

#create images RG
New-AzResourceGroup -Name $rg -Location $location

#list of gold images to create
$images = "elasticmaster"

#host file for Ansible were IP are going to be output
New-Item -Path . -Name "hosts" -ItemType "file"

#generate SSH key for login
#ssh-keygen -t rsa -b 4096 -f "master.key"

#loop for image creation
foreach($image in $images){
    $vm = New-AzVm `
        -ResourceGroupName $rg `
        -Name $image `
        -Location $location `
        -VirtualNetworkName "images_net" `
        -SubnetName "images_sn" `
        -Image "UbuntuLTS" `
        -Credential $credentials

    #add the ip and name to the host file for ansible
    $ip = Get-AzPublicIpAddress -Name $image -ResourceGroupName $rg
    Add-Content -Path "hosts" "[$image]"
    Add-Content -Path "hosts" $ip.IpAddress

    #Add-AzVMSshPublicKey -VM $vm -Path "./master.key.pub"
    # -VM $vm -DisablePasswordAuthentication -Linux
}

Move-Item -Path "hosts" -Destination "ansible/hosts"
#Move-Item -Path "master.key" -Destination "ansible/master.key"

ansible-playbook elastic.yml -i hosts -u "jorges" --private-key "master.key"