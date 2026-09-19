import UIKit
import Flutter

class BetaLaunchScreen: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.027, green: 0.067, blue: 0.15, alpha: 1.0)
        setupUI()
    }

    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
        ])

        let iconView = UIView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 24
        iconView.clipsToBounds = true

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.302, green: 0.784, blue: 0.941, alpha: 1.0).cgColor,
            UIColor(red: 0.545, green: 0.361, blue: 0.965, alpha: 1.0).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 24
        iconView.layer.addSublayer(gradientLayer)

        let letterLabel = UILabel()
        letterLabel.text = "B"
        letterLabel.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        letterLabel.textColor = .white
        letterLabel.textAlignment = .center
        letterLabel.translatesAutoresizingMaskIntoConstraints = false
        iconView.addSubview(letterLabel)

        stackView.addArrangedSubview(iconView)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 96),
            iconView.heightAnchor.constraint(equalToConstant: 96),
            letterLabel.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            letterLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
        ])

        let titleLabel = UILabel()
        titleLabel.text = "Beta"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        stackView.addArrangedSubview(titleLabel)

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = UIColor(red: 0.302, green: 0.784, blue: 0.941, alpha: 0.6)
        activityIndicator.startAnimating()
        stackView.addArrangedSubview(activityIndicator)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradientLayer = view.layer.sublayers?.compactMap({ $0 as? CAGradientLayer }).first {
            gradientLayer.frame = view.bounds
        }
    }
}
