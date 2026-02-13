<?php

declare(strict_types=1);

namespace Symfony\Component\DependencyInjection\Loader\Configurator;

return static function (ContainerConfigurator $container): void
{
	$container->extension('api_platform', [
		'title' => 'Eriu API',
		'version' => '1.0.0',
		'defaults' => [
			'stateless' => true,
			'cache_headers' => [
				'vary' => ['Content-Type', 'Authorization', 'Origin'],
			],
		],
		'formats' => [
			'jsonld' => ['application/ld+json'],
			'json' => ['application/json'],
		],
		'docs_formats' => [
			'jsonld' => ['application/ld+json'],
			'jsonopenapi' => ['application/vnd.openapi+json'],
			'html' => ['text/html'],
		],
	]);
};
