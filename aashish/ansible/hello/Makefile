build:
	docker build -t hello-rails:latest .

push:
	docker tag hello-rails:latest learn-test-service-alb-207963293.ap-south-1.elb.amazonaws.com/hello-rails:latest
	docker push learn-test-service-alb-207963293.ap-south-1.elb.amazonaws.com/hello-rails:latest

test:
	bin/rails test