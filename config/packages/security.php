<?php

declare(strict_types=1);

namespace Symfony\Component\DependencyInjection\Loader\Configurator;

// Placeholder security config using in-memory provider.
// Switch to entity provider when App\Entity\User is created.

return static function (ContainerConfigurator $container): void
{
	$container->extension('security', [
		'password_hashers' => [
			'Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface' => 'auto',
		],
		'providers' => [
			'users_in_memory' => [
				'memory' => null,
			],
		],
		'firewalls' => [
			'dev' => [
				'pattern' => '^/(_(profiler|wdt)|css|images|js)/',
				'security' => false,
			],
			'main' => [
				'lazy' => true,
				'provider' => 'users_in_memory',
			],
		],
	]);
};
