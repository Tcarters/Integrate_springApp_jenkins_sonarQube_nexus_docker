FROM maven as build
LABEL maintainer=" Tcarters a.k.a @Tdmund_"
WORKDIR /app 
COPY . .
RUN mvn install 

FROM openjdk:11.0
WORKDIR /app
COPY --from=build /app/target/javaspringapp-v01.jar /app/

EXPOSE 8080
CMD [ "java", "-jar", "javaspringapp-v01.jar" ]