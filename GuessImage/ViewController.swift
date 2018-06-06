//
//  ViewController.swift
//  GuessImage
//
//  Created by Anders Hovmöller on 2018-06-01.
//  Copyright © 2018 Anders Hovmöller. All rights reserved.
//

import UIKit

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

class ViewController: UIViewController {
    
    var imageViews: [AnswerView] = []
    var imagePaths: [String] = []
    let labelHeight: CGFloat = 100
    var labelView: UILabel = UILabel()
    var correctAnswer: String? = nil
    var nowShowing: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isMultipleTouchEnabled = true

        DispatchQueue.main.async {
            if let urls = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: "images") {
                self.imagePaths = urls.map { $0.path }
            }

            self.view.backgroundColor = .black
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
        
        imagePaths.shuffle()
        
        nowShowing = []
        for (path, imageView) in zip(imagePaths, imageViews) {
            DispatchQueue.main.async {
                imageView.image = UIImage(contentsOfFile: path)
            }
            let answer = String(path.split(separator: "/").last!.split(separator:".").first!)
            imageView.answer = answer
            nowShowing.append(answer)
        }
        
        correctAnswer = nowShowing.shuffled()[0]
        labelView.text = correctAnswer?.uppercased()
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
        }
        else {
            tappedView.image = nil
            tappedView.backgroundColor = .red
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

