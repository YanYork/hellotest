/*Public key Varibale*/
#+++++++++++++++++++++++
variable "ssh_key_public" {
    type    = string
    default = "path to public key"
}

/*Private key variable*/
#++++++++++++++++++++++++
variable "ssh_key_private" {
    type    = string
    default = "path to private key"
}
