module.exports = function(grunt){
  
  require("load-grunt-tasks")(grunt)

  grunt.option('stack',true)

  grunt.registerTask('release',[
    "fileExists:bin"
    ,"checkport"
    ,"gitcheckout:master"
    ,"gitadd:all"
    ,"gitstatuscheck"
    ,"prompt:release"
    ,"clean:reports"
    ,"protractor"
    ,"version::patch"
    ,"build"
    ,"clean:packages"
    ,"electron"
    ,"compress"
    ,"readme"
    ,"gitadd:all"
    ,"gitcommit:release"
    ,"tagrelease"
    ,"gitpush:master"
    ,"wait:ten"
    ,"githubAsset"
  ])

  grunt.registerTask('contracts',["concat:contracts","solc","solc-output-deploy","create-info-js"])

  grunt.registerTask('build',["clean:workspaces", "concat", "contracts", "index", "copy"])

  grunt.registerTask('run',["build", "watch"])

}