cd Server &&
mvn package &&
{
  mvn exec:java -Dexec.mainClass="com.oose2016.group4.server.Bootstrap" &
      cd ../SurvivalApp &&
            pod install &&
	            xcodebuild test -workspace Survival.xcworkspace -scheme Survival -destination 'platform=iOS Simulator,name=iPhone 7'
}
