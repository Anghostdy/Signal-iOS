//
// Copyright 2022 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import SignalUI
import SignalServiceKit
import SignalMessaging

class DonateChoosePaymentMethodSheet: OWSTableSheetViewController {
    enum DonationMode {
        case oneTime
        case monthly
        case gift
    }

    private let amount: FiatMoney
    private let badge: ProfileBadge?
    private let donationMode: DonationMode
    private let didChoosePaymentMethod: (DonateChoosePaymentMethodSheet) -> Void

    private let buttonHeight: CGFloat = 48

    private var titleText: String {
        let currencyString = DonationUtilities.format(money: amount)
        switch donationMode {
        case .oneTime:
            let format = NSLocalizedString(
                "DONATE_CHOOSE_PAYMENT_METHOD_SHEET_TITLE_FOR_ONE_TIME_DONATION",
                comment: "When users make one-time donations, they see a sheet that lets them pick a payment method. It also tells them what they'll be doing when they pay. This is the title on that sheet. Embeds {{amount of money}}, such as \"$5\"."
            )
            return String(format: format, currencyString)
        case .monthly:
            let moneyPerMonthFormat = NSLocalizedString(
                "SUSTAINER_VIEW_PRICING",
                comment: "Pricing text for sustainer view badges, embeds {{price}}"
            )
            let moneyPerMonthString = String(format: moneyPerMonthFormat, currencyString)
            let format = NSLocalizedString(
                "DONATE_CHOOSE_PAYMENT_METHOD_SHEET_TITLE_FOR_MONTHLY_DONATION",
                comment: "When users make monthly donations, they see a sheet that lets them pick a payment method. It also tells them what they'll be doing when they pay. This is the title on that sheet. Embeds {{amount of money per month}}, such as \"$5/month\"."
            )
            return String(format: format, moneyPerMonthString)
        case .gift:
            owsFail("Not yet supported.")
        }
    }

    private var bodyText: String? {
        guard let badge = badge else { return nil }

        let format: String
        switch donationMode {
        case .oneTime:
            format = NSLocalizedString(
                "DONATE_CHOOSE_PAYMENT_METHOD_SHEET_SUBTITLE_FOR_ONE_TIME_DONATION",
                comment: "When users make one-time donations, they see a sheet that lets them pick a payment method. It also tells them what they'll be doing when they pay: receive a badge for a month. This is the subtitle on that sheet. Embeds {{localized badge name}}, such as \"Boost\"."
            )
        case .monthly:
            format = NSLocalizedString(
                "DONATE_CHOOSE_PAYMENT_METHOD_SHEET_SUBTITLE_FOR_MONTHLY_DONATION",
                comment: "When users make monthly donations, they see a sheet that lets them pick a payment method. It also tells them what they'll be doing when they pay: receive a badge. This is the subtitle on that sheet. Embeds {{localized badge name}}, such as \"Planet\"."
            )
        case .gift:
            owsFail("Not yet supported.")
        }
        return String(format: format, badge.localizedName)
    }

    init(
        amount: FiatMoney,
        badge: ProfileBadge?,
        donationMode: DonationMode,
        didChoosePaymentMethod: @escaping (DonateChoosePaymentMethodSheet) -> Void
    ) {
        self.amount = amount
        self.badge = badge
        self.donationMode = donationMode
        self.didChoosePaymentMethod = didChoosePaymentMethod

        super.init()
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    // MARK: - Updating table contents

    public override func updateTableContents(shouldReload: Bool = true) {
        updateTop(shouldReload: shouldReload)
        updateBottom()
    }

    private func updateTop(shouldReload: Bool) {
        let infoStackView: UIView = {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.alignment = .center
            stackView.spacing = 6

            if let assets = self.badge?.assets {
                let badgeImageView = UIImageView(image: assets.universal112)
                badgeImageView.autoSetDimensions(to: CGSize(square: 112))
                stackView.addArrangedSubview(badgeImageView)
                stackView.setCustomSpacing(12, after: badgeImageView)
            }

            let titleLabel = UILabel()
            titleLabel.font = .ows_dynamicTypeTitle2.ows_semibold
            titleLabel.textColor = Theme.primaryTextColor
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.text = self.titleText
            stackView.addArrangedSubview(titleLabel)

            if let bodyText = self.bodyText {
                let bodyLabel = UILabel()
                bodyLabel.font = .ows_dynamicTypeBody
                bodyLabel.textColor = Theme.primaryTextColor
                bodyLabel.textAlignment = .center
                bodyLabel.numberOfLines = 0
                bodyLabel.lineBreakMode = .byWordWrapping
                bodyLabel.text = bodyText
                stackView.addArrangedSubview(bodyLabel)
            }

            return stackView
        }()

        let section = OWSTableSection(items: [.init(customCellBlock: {
            let cell = OWSTableItem.newCell()
            cell.contentView.addSubview(infoStackView)
            infoStackView.autoPinEdgesToSuperviewMargins()
            return cell
        })])
        section.hasBackground = false
        let contents = OWSTableContents(sections: [section])

        self.tableViewController.setContents(contents, shouldReload: shouldReload)
    }

    private func updateBottom() {
        let paymentButtonContainerView: UIView = {
            // TODO(donations) When we add other payment methods, we should hide this button if Apple Pay is unavailable.
            let applePayButton = ApplePayButton { [weak self] in
                guard let self = self else { return }
                self.didChoosePaymentMethod(self)
            }

            let stackView = UIStackView(arrangedSubviews: [applePayButton])
            stackView.axis = .vertical
            stackView.alignment = .fill
            stackView.spacing = 12

            applePayButton.autoSetDimension(.height, toSize: buttonHeight)

            return stackView
        }()

        footerStack.removeAllSubviews()
        footerStack.addArrangedSubview(paymentButtonContainerView)
        footerStack.alignment = .fill
        footerStack.layoutMargins = UIEdgeInsets(top: 28, left: 40, bottom: 8, right: 40)
        footerStack.isLayoutMarginsRelativeArrangement = true

        paymentButtonContainerView.autoPinWidthToSuperviewMargins()
    }
}