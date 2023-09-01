resource "null_resource" "configure_fortigate" {
  count = var.deploy_cfg ? 1 : 0 # Only create if toggle_cfg is true

  triggers = {
    instance_id = aws_instance.ftg_instance[0].id
    script      = local.config_script
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${local.config_script}' > /tmp/config_script",
      "ssh admin@${aws_network_interface.mgmt_eni[0].private_ip} 'bash /tmp/config_script'"
    ]

    connection {
      type     = "ssh"
      user     = "admin"
      password = aws_instance.ftg_instance[0].id
      host     = aws_network_interface.mgmt_eni[0].private_ip
    }
  }
}
