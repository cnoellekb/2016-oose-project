cd Server &&
mvn package &&
{
  mvn exec:java -Dexec.mainClass="com.oose2016.group4.server.Bootstrap" &
  cd ../SurvivalApp &&
  xcodebuild build build-for-testing -scheme 'Survival' -destination 'name=iPhone SE'
  xcodebuild test-without-building -scheme 'Survival' -destination 'name=iPhone SE'
}
