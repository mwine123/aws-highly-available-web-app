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

A NAT Gateway was considered for this project so that the EC2 instances can connect to the internet without the internet 
being able to initiate a connection with the instances. The NAT Gateway would have been used to fetch the packages needed
for patch management in the instances however, it is charged per hour and per gigabyte of data processed. I decided to save 
cost by using the Amazon Linux OS instead and configuring a VPC S3 endpoint to fetch the packages from S3 where the Amazon
Linux repos live because the gateway endpoint has no hourly or data charge.

I wrote a line in my user data that used IMDSv2 to retrieve some metadata because said metadata lives where the credentials for the 
assume role we created for the instance to be able to access S3 buckets live and we did not want accidental data leaks. The IMDSv2
protects against simple GET SSRF attacks by using a PUT to request a session token before it fetches any metadata. SSRF attacks can 
usually only trigger simple GET requests. It also has a Hop Limit Control. It lets you set a response hop limit (TTL) to 2, this 
limits how many network hops the response can travel and prevents other services, containerised workloads or proxies running in 
the instance from relaying the metadata response further than intended. 

I wrote an IAM role policy to allow the instances list and get the objects in the S3 bucket that contains the static website files.
Initially, I had a wildcard allowing simple AmazonS3ReadOnlyAccess to my account-wide s3 buckets. I then scoped it down to allow s3:GetObject and 
s3:ListBucket from only the bucket with the website and the resources in the bucket. This is so that if an attacker obtains the instance 
credentials, the attacker can only read my public website files which are already public.
