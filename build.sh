cd Server &&
mvn package &&
{
  mvn exec:java -Dexec.mainClass="com.oose2016.group4.server.Bootstrap" &
  cd ../SurvivalApp &&
  xcodebuild clean build build-for-testing -scheme 'Survival' -destination 'OS=10.1,name=iPhone 7'
  xcodebuild test-without-building -scheme 'Survival' -destination 'OS=10.1,name=iPhone 7'
}
