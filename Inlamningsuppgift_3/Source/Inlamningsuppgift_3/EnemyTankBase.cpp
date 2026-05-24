// Fill out your copyright notice in the Description page of Project Settings.


#include "EnemyTankBase.h"
#include "EnemyTankMovementComponent.h"

// Sets default values
AEnemyTankBase::AEnemyTankBase()
{
 	// Set this pawn to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
    TankMovement = CreateDefaultSubobject<UEnemyTankMovementComponent>(TEXT("TankMovement"));

}

// Called when the game starts or when spawned
void AEnemyTankBase::BeginPlay()
{
	Super::BeginPlay();
	
}

// Called every frame
void AEnemyTankBase::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

// Called to bind functionality to input
void AEnemyTankBase::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

}

