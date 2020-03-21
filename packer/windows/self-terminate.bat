curl -s http://169.254.169.254/latest/meta-data/instance-id > instance-id.txt
set /p INSTANCE_ID=<instance-id.txt
aws ec2 terminate-instances --instance-ids %INSTANCE_ID%
