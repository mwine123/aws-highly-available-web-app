# aws-highly-available-web-app
A website hosted on 2 ec2 instances in a VPC, built for high availability with failover tested across 2 availability zones. 
This project is an opportunity for me to learn more and get some hands on practice. It is a 
highly available website hosted in two EC2 instances in the private subnets of a VPC in two AZs. The instances are
attached to an autoscaling group and an s3 endpoint for the instances to get the files for the website from an s3 bucket.
An application load balancer is placed in the public subnets to receive and route traffic into the instances and an
internet gateway to connect the VPC to the internet.


![Architecture diagram](images/architecture.png)

## Architecture decisions
The EC2 instances are in the private subnets and not the public subnets. I made this decision because I want the
Application Load Balancer to be the only way into the EC2 instances. This will ensure that all configurations and controls 
on the ALB (security) applies and the ALB can route traffic around a failed or unhealthy instance (availability). If the 
EC2 instances are in the public subnet, all those controls become optional.

I have two security groups in this project, the first one is the ALB security group with an inbound rule that allows HTTP 
on port 80 from IPv4 anywhere so that traffic from anywhere can get to it. The second security group is the instance 
security group with an inbound rule that only allows HTTP on port 80 from the ALB security group. I used the ALB security 
group and not the ip address because the ip address is not static and can change but the security group reference will remain 
the same regardless of what the ip address of the ALB is.
