name := "BigCorpProj"

version := "0.1"

scalaVersion := "2.11.12"

val sparkVersion= "2.3.0"

parallelExecution in Test := false

fork in Test := true
javaOptions ++= Seq("-Xms512M", "-Xmx2048M", "-XX:MaxPermSize=2048M", "-XX:+CMSClassUnloadingEnabled")
libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-sql" % sparkVersion
).map(_ % "provided")

resolvers += "jitpack" at "https://jitpack.io"

libraryDependencies ++= Seq(
  "com.databricks" %% "dbutils-api" % "0.0.3",
  "com.github.MrPowers" % "spark-daria" % s"v${sparkVersion}_0.24.0"
)

// Test dependencies
libraryDependencies ++= Seq(
  "com.holdenkarau" %% "spark-testing-base" % s"${sparkVersion}_0.9.0",
  "org.apache.spark" %% "spark-hive" % sparkVersion,
  "org.apache.spark" %% "spark-core" % sparkVersion,
  "org.scalamock" %% "scalamock" % "4.1.0",
  "org.scalatest" %% "scalatest" % "3.0.5"
).map(_ % "test")

assemblyOption in assembly := (assemblyOption in assembly).value.copy(includeScala = false) // Exclude Scala libs

// Add fat JAR to published artifacts
artifact in (Compile, assembly) := {
  val art = (artifact in (Compile, assembly)).value
  art.copy(`classifier` = Some("assembly"))
}

addArtifact(artifact in (Compile, assembly), assembly)

assemblyMergeStrategy in assembly := {
  case PathList("META-INF", _ @ _*) => MergeStrategy.discard
  case _ => MergeStrategy.first
}
