#get credentials for gold images and set vars
$credentials = Get-Credential
$location = "West US 2"
$rg = "tmp_elk_images"
$vnetName = "tmp_net"
$subnetName = "tmp_subnet"
$nsgName = "nsg"

#creat images tmp RG
New-AzResourceGroup -Name $rg -Location $location

#list of gold images to create
$images = "elasticmaster", "elasticnode1", "elasticnode2"

#host file for Ansible were IP are going to be output
New-Item -Path . -Name "hosts" -ItemType "file"

#create VNet
$rule1 = New-AzNetworkSecurityRuleConfig -Name "9200" -Description "Elastic 9200" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 9200

$rule2 = New-AzNetworkSecurityRuleConfig -Name "9300" -Description "Elastic 9300" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix `
    VirtualNetwork -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 9300

$rule3 = New-AzNetworkSecurityRuleConfig -Name "SSH" -Description "SSH" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 102 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22

$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $rg -Location $location -Name $nsgName -SecurityRules $rule1,$rule2,$rule3

$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.1.0/24" -NetworkSecurityGroup $nsg
New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rg -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $subnet

#loop for image creation
foreach($image in $images){
    $vm = New-AzVm `
        -ResourceGroupName $rg `
        -Name $image `
        -Location $location `
        -VirtualNetworkName $vnetName `
        -SubnetName $subnetName `
        -Image "UbuntuLTS" `
        -Credential $credentials `
        -Size Standard_B2s `
        -OpenPorts 9200,9300,22

    #add the ip and name to the host file for ansible
    $ip = Get-AzPublicIpAddress -Name $image -ResourceGroupName $rg
    Add-Content -Path "hosts" "[$image]"
    Add-Content -Path "hosts" $ip.IpAddress
}

Move-Item -Path "hosts" -Destination "ansible/hosts"

#ansible-playbook ./ansible/elastic.yml -i hosts -k -u "jorges"

#image gallery rg variables
$gallery_rg = "elk_gallery"

#creat image gallery RG
New-AzResourceGroup -Name $gallery_rg -Location $location

$gallery = New-AzGallery `
   -GalleryName 'elk_gallery' `
   -ResourceGroupName $gallery_rg `
   -Location $location `
   -Description 'Shared Image Gallery for ELK Stack'

#loop for image creation
foreach($image in $images){
    $galleryImage = New-AzGalleryImageDefinition `
        -GalleryName $gallery.Name `
        -ResourceGroupName $gallery_rg `
        -Location $location `
        -Name $image `
        -OsState specialized `
        -OsType Linux `
        -Publisher 'gorj3' `
        -Offer $image `
        -Sku $
        
    $region1 = @{Name='South Central US';ReplicaCount=1}
    $region2 = @{Name='East US';ReplicaCount=2}
    $targetRegions = @($region1,$region2)
     
     New-AzGalleryImageVersion `
        -GalleryImageDefinitionName $galleryImage.Name`
        -GalleryImageVersionName '1.0.0' `
        -GalleryName $gallery.Name `
        -ResourceGroupName $resourceGroup.ResourceGroupName `
        -Location $resourceGroup.Location `
        -TargetRegion $targetRegions  `
        -Source $sourceVM.Id.ToString() `
        -PublishingProfileEndOfLifeDate '2020-12-01'
}