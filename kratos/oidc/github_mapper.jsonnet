local claims = std.extVar('claims');

{
  identity: {
    traits: {
      email: claims.email,
      [if std.objectHas(claims, 'name') && claims.name != null then 'name']: {
        first: if std.objectHas(claims, 'name') && claims.name != null then
          std.split(claims.name, ' ')[0]
        else
          '',
        last: if std.objectHas(claims, 'name') && claims.name != null && std.length(std.split(claims.name, ' ')) > 1 then
          std.join(' ', std.slice(std.split(claims.name, ' '), 1, std.length(std.split(claims.name, ' ')), 1))
        else
          '',
      },
    },
  },
}
