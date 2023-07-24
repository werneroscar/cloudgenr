resource "aws_db_instance" "asg-database" {
  allocated_storage    = 10
  # db_subnet_group_name = aws_db_subnet_group.asg-db-sg.name
  db_name              = "mydb"
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  username             = "cloudgenuser"
  password             = "cloudgenuser"
  skip_final_snapshot  = true
}
