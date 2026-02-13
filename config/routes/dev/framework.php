<?php

declare(strict_types=1);

namespace Symfony\Component\Routing\Loader\Configurator;

return static function (RoutingConfigurator $routes): void
{
	$routes->import('@FrameworkBundle/Resources/config/routing/errors.php')
		->prefix('/_error');
};
