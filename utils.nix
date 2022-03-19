{
  mkTraefikRoute = name: localUrl: {
    http.routers.${name} = {
      rule = "Host(`${name}.h.jackrose.co.nz`)";
      service = "${name}";
      tls.certResolver = "default";
    };
    http.services.${name}.loadBalancer.servers = [{
      url = "${localUrl}";
    }];
  };

  mkProtectedTraefikRoute = name: localUrl: {
    http.routers.${name} = {
      rule = "Host(`${name}.h.jackrose.co.nz`)";
      service = "${name}";
      tls.certResolver = "default";
      middlewares = "authelia@file";
    };
    http.services.${name}.loadBalancer.servers = [{
      url = "${localUrl}";
    }];
  };
}
