var atomicalgolia = require("atomic-algolia")
var indexName = "test-index"
var indexPath = "./public/index.json"
var cb = function(error, result) {
    if (error) throw error

    console.log(result)
}

atomicalgolia(indexName, indexPath, cb)