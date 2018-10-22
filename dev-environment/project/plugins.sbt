resolvers += "bintray-spark-packages" at "https://dl.bintray.com/databricks/maven/"
addSbtPlugin("com.databricks" %% "sbt-databricks" % "0.1.5")
addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "0.14.6")
addSbtPlugin("net.virtual-void" % "sbt-dependency-graph" % "0.9.0")
addSbtPlugin("org.scalastyle" %% "scalastyle-sbt-plugin" % "1.0.0")
addSbtPlugin("org.scoverage" % "sbt-scoverage" % "1.3.5")
