# Russian plural forms: 1 товар, 2 товара, 5 товаров, 1,5 товара.
{
  ru: {
    i18n: {
      plural: {
        keys: %i[one few many other],
        rule: lambda do |count|
          next :other unless count.is_a?(Integer)

          mod10 = count % 10
          mod100 = count % 100

          if mod10 == 1 && mod100 != 11
            :one
          elsif (2..4).cover?(mod10) && !(12..14).cover?(mod100)
            :few
          else
            :many
          end
        end
      }
    }
  }
}
