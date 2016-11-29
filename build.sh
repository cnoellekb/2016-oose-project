cd Server &&
mvn package &&
{
  mvn exec:java -Dexec.mainClass="com.oose2016.group4.server.Bootstrap" &
  cd ../SurvivalApp &&
  xcodebuild test -scheme 'Survival' -destination 'OS=10.1,name=iPhone 7'
}
