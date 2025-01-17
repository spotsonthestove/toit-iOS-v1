import UIKit

class NodeLabelView: UIView {
    private let label = UILabel()
    
    init(frame: CGRect, text: String) {
        super.init(frame: frame)
        setupLabel(text: text)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLabel(text: String) {
        label.text = text
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.textColor = .white
        label.font = .systemFont(ofSize: 12)
        
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func updatePosition(_ position: CGPoint) {
        center = position
    }
} 