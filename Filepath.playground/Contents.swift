/// A representation of a path leading to one resource, which may terminate in a directory or an individual file.
/// Additional enhancements could include separating a file's name and extension
enum Filepath {
    case file(String)
    indirect case directory(String, Filepath?)
}

/// Adds a capability for a constant understanding of a separator character and a computed variable that will allow the Filepath
/// to appear as a typical Filepath may on a filesystem. ie: test/test1.txt
extension Filepath {
    static let separator = Character("/")

    /// A string representation of the filepath. Directories always have postfix of the separator, where files do not.
    var description: String {
        switch self {
        case .directory(let name, let path):
            let pathDescription = path?.description ?? ""
            return "\(name)\(Filepath.separator)\(pathDescription)"
        case .file(let value):
            return value
        }
    }
}

/// Adds a more imperative api onto Filepath for varied usecases and API ergonomics
extension Filepath {

    /// The next path element if there is one
    var nextPath:Filepath? {
        switch self {
        case .directory(_, let path):
            return path
        case .file(_):
            return nil
        }
    }

    /// The name of the current Filepath
    var name:String {
        switch self {
        case .directory(let name, _):
            return name
        case .file(let name):
            return name
        }
    }
}

extension Filepath: ExpressibleByStringLiteral {

    /// Adds the capability to be expressed by a String, which will allow for a model to be built
    /// that will read in a better manner. i.e. let path:Filepath = "/test/test.txt"
    /// As conformance to this protocol does not allow initialization failure, an empty directory is
    /// returned upon initialization if there are no path tokens, ie: an empty String.
    /// A string of just separator characters will be interpreted as a single directory.
    /// Admittedly not as robust as an actual path parsing would need to be to account for user error,
    /// escaped characters, etc.
    init(stringLiteral value: String) {
        let pathEndsInFile = value.last != Filepath.separator
        let isAbsolutePath = value.first == Filepath.separator

        var tokens = value.split(separator: Filepath.separator)

        guard !tokens.isEmpty else {
            print("There are no tokens")
            self = .directory("", nil)
            return
        }

        let lastToken = tokens.removeLast()

        if pathEndsInFile  {
            self = Filepath.file(String(lastToken))
        } else {
            self = Filepath.directory(String(lastToken), nil)
        }

        while !tokens.isEmpty {
            self = .directory(String(tokens.removeLast()), self)
        }

        if isAbsolutePath {
            self = .directory("", self)
        }
    }
}

import XCTest

class FilepathTests:XCTestCase {
    func testFilepathCreation() {
        let fp:Filepath = Filepath.directory("test1",.directory("test2",.file("test3.txt")))

        XCTAssertEqual(fp.description, "test1/test2/test3.txt")

        XCTAssertEqual("test1", fp.name)
        XCTAssertEqual("test2", fp.nextPath!.name)
        XCTAssertEqual("test3.txt", fp.nextPath!.nextPath!.name)
    }

    func testStringFilepathWithLeadingSlash() {
        let fp:Filepath = "/a/b/c/"
        XCTAssertEqual(fp.description, "/a/b/c/")
    }

    func testStringFilepathWithOutLeadingSlash() {
        let fp:Filepath = "a/b/c/"
        XCTAssertEqual(fp.description, "a/b/c/")
    }

    func testEmptyStringFilepath() {
        let fp:Filepath = ""
        XCTAssertEqual(fp.description, "/")
    }

    func testSingleDirectory() {
        let fp:Filepath = "a/"
        XCTAssertEqual(fp.description, "a/")
    }

    func testSingleFile() {
        let fp:Filepath = "a"
        XCTAssertEqual(fp.description, "a")
    }

    func testSingleDirAndFile() {
        let fp:Filepath = "/a"
        XCTAssertEqual(fp.description, "/a")
    }

    func testDirWithNoName() {
        let fp:Filepath = "/ /"
        XCTAssertEqual(fp.description, "/ /")

        if case let Filepath.directory(name, filepath) = fp {
            XCTAssertEqual("", name)
            if let filepath = filepath, case let Filepath.directory(nxtName, _) = filepath {
                XCTAssertEqual(" ", nxtName)
            } else {
                XCTFail("Filepath: \(String(describing: filepath))")
            }
        } else {
            XCTFail("Filepath fp: \(fp)")
        }
    }

    func testDoubleDir() {
        let fp:Filepath = "//"
        XCTAssertEqual(fp.description, "/")
    }
}

FilepathTests.defaultTestSuite.run()
