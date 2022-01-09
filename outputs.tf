/*Return public subnets*/
#+++++++++++++++++++++++++
output "public_subnets" {
  value = aws_subnet.main_public_subnet.id
}

/*Return my sg*/
#++++++++++++++++
output "public_sg" {
  value = aws_security_group.allow_tls.id
}

/*Return server ID*/
#++++++++++++++++++++
output "server_id" {
  value =  aws_instance.main.id
}

/*Return webserver IP*/
#+++++++++++++++++++++++
output "server_ip" {
  value = aws_instance.main.public_ip
}
