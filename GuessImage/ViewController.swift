//
//  ViewController.swift
//  GuessImage
//
//  Created by Anders Hovmöller on 2018-06-01.
//  Copyright © 2018 Anders Hovmöller. All rights reserved.
//

import UIKit
import AVFoundation

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            // Change `Int` in the next line to `IndexDistance` in < Swift 4.1
            let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

class AnswerView: UIImageView {
    var answer: String? = nil
    weak var vc: ViewController? = nil
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        vc!.tap(tappedView: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        vc!.tap(tappedView: self)
    }
}

class NewGameView: UIImageView {
    weak var vc: ViewController? = nil
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        vc!.tapNewGame()
    }
}

func paths(forResourcesWithExtension : String, subdirectory : String) -> [String] {
    if let urls = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: "images") {
        return urls.map { $0.path }
    }
    assert(false)
}

class ViewController: UIViewController {
    
    var imageViews: [AnswerView] = []
    var imagePaths: [String] = []
    var rightAnswersImagePaths: [String] = []
    let labelHeight: CGFloat = 100
    var labelView: UILabel = UILabel()
    var correctAnswer: String? = nil
    var nowShowing: [String] = []
    var upperCase = true

    var correctAnswerSounds: [URL] = []
    var wrongAnswerSounds: [URL] = []
    
    var audioPlayer: AVAudioPlayer? = nil;

    override func viewDidLoad() {
        super.viewDidLoad()
        view.isMultipleTouchEnabled = true
        self.view.backgroundColor = .black

        DispatchQueue.main.async {
            self.imagePaths = paths(forResourcesWithExtension: "jpg", subdirectory: "images")
            if let urls = Bundle.main.urls(forResourcesWithExtension: "m4a", subdirectory: "correct_sounds") {
                self.correctAnswerSounds = urls
            }
            if let urls = Bundle.main.urls(forResourcesWithExtension: "m4a", subdirectory: "wrong_sounds") {
                self.wrongAnswerSounds = urls
            }

            self.labelView.frame = CGRect(
                x: 0,
                y: self.view.frame.size.height - self.labelHeight,
                width: self.view.frame.size.width,
                height: self.labelHeight)
            self.labelView.textColor = .white
            self.labelView.adjustsFontSizeToFitWidth = true
            self.labelView.font = self.labelView.font.withSize(80)
            self.labelView.textAlignment = .center
            
            self.newGame()
        }
        labelView.isUserInteractionEnabled = true
        labelView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(changeCase)))
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        self.labelView.frame = CGRect(
            x: 0,
            y: self.view.frame.size.height - self.labelHeight,
            width: self.view.frame.size.width,
            height: self.labelHeight)
    }
    
    @objc
    func changeCase() {
        upperCase = !upperCase
        setLabel()
    }
    
    func removeSubviews() {
        for v in view.subviews {
            if v == labelView {
                continue
            }
            v.removeFromSuperview()
        }
    }
    
    func newGame() {
        removeSubviews()
        imageViews = []
        
        view.addSubview(labelView)
        
        let columns = 2
        let rows = 4
        for i in 0..<columns {
            createColumn(
                columnIndex: i,
                totalNumberOfColumns: columns,
                rows: rows
            )
        }
        
        if rightAnswersImagePaths.isEmpty {
            rightAnswersImagePaths = imagePaths.shuffled()
        }
        
        let correctAnswerPath = rightAnswersImagePaths.popLast()!
        let wrongAnswersPath = (imagePaths.shuffled().filter {$0 != correctAnswerPath})[..<(rows * columns - 1)]
        
        let alternativesToShowPaths = ([correctAnswerPath] + wrongAnswersPath).shuffled()
        assert(alternativesToShowPaths.count == imageViews.count)

        nowShowing = []
        for (path, imageView) in zip(alternativesToShowPaths, imageViews) {
            DispatchQueue.main.async {
                imageView.image = UIImage(contentsOfFile: path)
            }
            let answer = String(path.split(separator: "/").last!.split(separator:".").first!)
            if path == correctAnswerPath {
                correctAnswer = answer;
            }
            imageView.answer = answer
            nowShowing.append(answer)
        }
        setLabel()
    }
    
    func setLabel() {
        let t = Bundle.main.localizedString(forKey: correctAnswer ?? "", value: nil, table: nil)
        if upperCase {
            labelView.text = t.uppercased()
        }
        else {
            labelView.text = t.lowercased()
        }
    }
    
    func translateViewToAnswer(_ view: UIView) -> String {
        for (answer, imageView) in zip(nowShowing, imageViews) {
            if imageView == view {
                return answer
            }
        }
        assert(false)
    }
    
    func tapNewGame() {
        newGame()
    }
    
    func tap(tappedView: AnswerView) {
        let tappedAnswer = translateViewToAnswer(tappedView)
        if tappedAnswer == correctAnswer {
            let newGameView = NewGameView()
            newGameView.vc = self
            newGameView.contentMode = .scaleAspectFit
            newGameView.frame = view.frame
            newGameView.frame.size.height -= labelHeight
            newGameView.backgroundColor = .black
            newGameView.image = tappedView.image
            newGameView.isUserInteractionEnabled = true
            removeSubviews()
            view.addSubview(newGameView)
        
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: self.correctAnswerSounds.randomElement()!)
                self.audioPlayer!.play()
            }
            catch {
            }

        }
        else {
            tappedView.image = nil
            tappedView.backgroundColor = .red
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: self.wrongAnswerSounds.randomElement()!)
                self.audioPlayer!.play()
            }
            catch {
            }
        }
    }
    
    func createColumn(columnIndex : Int, totalNumberOfColumns : Int, rows: Int) {
        for i in 0..<rows {
            let answerView = AnswerView()
            let height = (view.frame.size.height - labelHeight) / CGFloat(rows)
            let width = view.frame.size.width / CGFloat(totalNumberOfColumns)
            answerView.contentMode = .scaleAspectFill
            answerView.clipsToBounds = true
            answerView.frame.origin.x = CGFloat(columnIndex) * width - 1
            answerView.frame.origin.y = height * CGFloat(i)
            answerView.frame.size.height = height
            answerView.frame.size.width = width + 1
            answerView.isUserInteractionEnabled = true
            answerView.vc = self
            view.addSubview(answerView)
            imageViews.append(answerView)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

