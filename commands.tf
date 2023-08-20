resource "null_resource" "provision_openvpn" {
  count = var.deploy_ovp ? 1 : 0
  triggers = {
    user        = var.ssh_user
    port        = var.ssh_port
    private_key = var.private_key_path # Updated to the path of the private key file
    host        = aws_eip.vpnserver_eip[0].public_ip
  }

  depends_on = [aws_instance.vpnserver, aws_eip.vpnserver_eip, aws_security_group.vpnec2]

  connection {
    type        = "ssh"
    user        = self.triggers.user
    port        = self.triggers.port
    private_key = file(self.triggers.private_key)
    host        = self.triggers.host
  }

  provisioner "remote-exec" {
    inline = [
      #"sudo apt-get -y update",
      #"sudo apt-get install -y dig curl vim git libltdl7 python3 python3-pip python software-properties-common unattended-upgrades", # Added dig??
      "sudo yum -y update",
      "sudo yum install -y bind-utils curl vim git libltdl7 python3 python3-pip python software-properties-common unattended-upgrades", # Converted to yum & dig from bind    

      "touch ~/provisioned", # Troll
    ]
  }
}

# provision core templates
resource "null_resource" "provision_core" {
  count = var.deploy_ovp ? 1 : 0
  triggers = {
    user        = var.ssh_user
    port        = var.ssh_port
    private_key = var.private_key_path # Updated to the path of the private key file
    host        = aws_eip.vpnserver_eip[0].public_ip
  }

  depends_on = [null_resource.provision_openvpn]

  connection {
    type        = "ssh"
    user        = self.triggers.user
    port        = self.triggers.port
    private_key = file(self.triggers.private_key)
    host        = self.triggers.host
  }

  provisioner "remote-exec" {
    inline = [
      format("%s %s", "rm -rf ", local.templates_path),
      format("%s %s", "mkdir -p ", local.templates_path),
    ]
  }

}

#installing openvpn through third-party openvpn script by dumrauf you can check it out here: https://github.com/dumrauf
resource "null_resource" "openvpn_install" {
  count = var.deploy_ovp ? 1 : 0
  triggers = {
    user        = var.ssh_user
    port        = var.ssh_port
    private_key = var.private_key_path # Updated to the path of the private key file
    host        = aws_eip.vpnserver_eip[0].public_ip
  }
  depends_on = [null_resource.provision_core]
  connection {
    type        = "ssh"
    user        = self.triggers.user
    port        = self.triggers.port
    private_key = file(self.triggers.private_key)
    host        = self.triggers.host
  }

  provisioner "file" {
    destination = local.templates.vpn.install.file
    content     = templatefile(local.templates.vpn.install.template, local.templates.vpn.install.vars)
  }

  provisioner "remote-exec" {
    inline = [
      format("%s %s", "sudo chmod a+x", local.templates.vpn.install.file),
      format("%s %s", "sudo ", local.templates.vpn.install.file),
    ]
  }

}

#adding user to connect to vpn through third party script by dumrauf you can check it out here: https://github.com/dumrauf
resource "null_resource" "openvpn_adduser" {
  count = var.deploy_ovp ? 1 : 0
  triggers = {
    user        = var.ssh_user
    port        = var.ssh_port
    private_key = var.private_key_path # Updated to the path of the private key file
    host        = aws_eip.vpnserver_eip[0].public_ip
  }

  depends_on = [null_resource.openvpn_install]

  connection {
    type        = "ssh"
    user        = self.triggers.user
    port        = self.triggers.port
    private_key = file(self.triggers.private_key)
    host        = self.triggers.host
  }

  provisioner "file" {
    destination = local.templates.vpn.update_user.file
    content     = templatefile(local.templates.vpn.update_user.template, local.templates.vpn.update_user.vars)
  }

  provisioner "remote-exec" {
    inline = [
      format("%s %s", "sudo chmod a+x", local.templates.vpn.update_user.file),
      format("%s %s", "sudo ", local.templates.vpn.update_user.file),
    ]
  }
}

#adding user to connect to vpn through third party script by dumrauf you can check it out here: https://github.com/dumrauf
resource "null_resource" "openvpn_move_files" {
  count = var.deploy_ovp ? 1 : 0
  triggers = {
    user        = var.ssh_user
    port        = var.ssh_port
    private_key = var.private_key_path # Updated to the path of the private key file
    host        = aws_eip.vpnserver_eip[0].public_ip
  }

  depends_on = [null_resource.openvpn_adduser]

  connection {
    type        = "ssh"
    user        = self.triggers.user
    port        = self.triggers.port
    private_key = file(self.triggers.private_key)
    host        = self.triggers.host
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /root/${var.admin_user}.ovpn /home/ec2-user/ ;",
      "sudo sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf ;",
      "sudo sysctl -p ;",
      "sudo sed -i 's#push \"redirect-gateway def1 bypass-dhcp\"#push \"route 10.0.0.0 255.0.0.0\"#' /etc/openvpn/server.conf", # push routes? maybe need 10.255.255.0
      "sudo systemctl restart openvpn@server",
      #"sudo sed -i 's#push \"dhcp-option DNS ${aws_route53_zone.private_zone.name_servers[0]}\"#' /etc/openvpn/server.conf" # push routes? maybe need 10.255.255.0
      #"sudo sed -i 's#push \"dhcp-option DNS ${values(aws_route53_zone.private_zone)[0].name_servers[0]}\"#' /etc/openvpn/server.conf"

    ]
  }

}


# download ovpn configurations to use with openvpn client
resource "null_resource" "openvpn_download_configurations" {
  count = var.deploy_ovp ? 1 : 0
  triggers = {
    user        = var.ssh_user
    port        = var.ssh_port
    private_key = var.private_key_path # Updated to the path of the private key file
    host        = aws_eip.vpnserver_eip[0].public_ip
  }

  depends_on = [null_resource.openvpn_move_files, aws_eip.vpnserver_eip]

  #provisioner "local-exec" {

  provisioner "local-exec" {
    command = <<-EOT
    mkdir ${local.local_path}\\${self.triggers.host}
  EOT
  }

  provisioner "local-exec" {
    command = <<-EOT
    scp -o StrictHostKeyChecking=no -i ${local.local_path}\key ${self.triggers.user}@${self.triggers.host}:/home/ec2-user/${var.admin_user}.ovpn ${local.local_path}\${self.triggers.host}\ >> ${local.local_path}\\scp_output.log 2>&1
  EOT
  }
}