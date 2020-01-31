# output "build-server" {
#     value = {
#         SSH = "ssh -i ~/keys/${var.key_pair}.pem ubuntu@${aws_instance.build-server.public_ip}"
#     }
# }

output "jenkins-server" {
    value = {
        # SSH = "ssh -i ~/keys/${var.key_pair}.pem ubuntu@${aws_instance.jenkins-server.public_ip}"
        IPAddress = aws_instance.jenkins-server.public_ip
        Interface = "http://${aws_instance.jenkins-server.public_ip}:8080/"
    }
}
