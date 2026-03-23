class AlertMailer < ApplicationMailer
  def risk_change(alert)
    @alert = alert
    @token = alert.token
    @user = alert.user

    mail(
      to: @user.email,
      subject: "CrypCop Alert: #{@alert.title}"
    )
  end
end
